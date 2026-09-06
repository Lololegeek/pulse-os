#include "pulseos/process.hpp"

#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/wait.h>
#include <unistd.h>

#include <array>
#include <cerrno>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <optional>
#include <set>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

namespace fs = std::filesystem;

namespace pulseos {
namespace {

constexpr int kIoPrioWhoProcess = 1;
constexpr int kIoPrioClassBestEffort = 2;
constexpr int kIoPrioClassShift = 13;
constexpr int kGamingNice = -5;
constexpr int kGamingIoPriority = 0;

const std::set<std::string> kIgnoredCommands = {
    "steam", "steamwebhelper", "steamservice", "gamescope",
    "pressure-vessel-wrap", "pressure-vessel-adverb", "pv-bwrap", "reaper",
    "explorer.exe", "services.exe", "wineserver", "winedevice.exe", "rpcss.exe"
};

std::optional<std::string> read_text_file(const fs::path& path) {
    std::ifstream input(path, std::ios::binary);
    if (!input) {
        return std::nullopt;
    }
    std::ostringstream out;
    out << input.rdbuf();
    return out.str();
}

std::optional<std::string> steam_app_id_from_environment(std::string_view environment) {
    std::size_t pos = 0;
    while (pos < environment.size()) {
        const auto end = environment.find('\0', pos);
        const auto item_end = end == std::string_view::npos ? environment.size() : end;
        const auto item = environment.substr(pos, item_end - pos);
        for (const std::string_view key : {std::string_view{"SteamAppId="}, std::string_view{"SteamGameId="}}) {
            if (item.starts_with(key)) {
                const auto value = item.substr(key.size());
                if (!value.empty() && value != "0" && value != "769") {
                    return std::string(value);
                }
            }
        }
        if (end == std::string_view::npos) {
            break;
        }
        pos = end + 1;
    }
    return std::nullopt;
}

std::optional<GameProcess> inspect_process(pid_t pid) {
    const fs::path base = fs::path{"/proc"} / std::to_string(pid);

    struct stat st {};
    if (::stat(base.c_str(), &st) != 0) {
        return std::nullopt;
    }

    const auto environment = read_text_file(base / "environ");
    if (!environment) {
        return std::nullopt;
    }
    const auto app_id = steam_app_id_from_environment(*environment);
    if (!app_id) {
        return std::nullopt;
    }

    const auto command_raw = read_text_file(base / "comm");
    if (!command_raw) {
        return std::nullopt;
    }
    std::string command = *command_raw;
    while (!command.empty() && (command.back() == '\n' || command.back() == '\r')) {
        command.pop_back();
    }
    if (kIgnoredCommands.contains(command)) {
        return std::nullopt;
    }

    return GameProcess{pid, st.st_uid, *app_id, std::move(command)};
}

bool run_program(const char* program, const std::vector<std::string>& args) {
    const pid_t child = ::fork();
    if (child < 0) {
        return false;
    }
    if (child == 0) {
        std::vector<char*> argv;
        argv.reserve(args.size() + 2);
        argv.push_back(const_cast<char*>(program));
        for (const auto& arg : args) {
            argv.push_back(const_cast<char*>(arg.c_str()));
        }
        argv.push_back(nullptr);
        ::execvp(program, argv.data());
        _exit(127);
    }

    int status = 0;
    while (::waitpid(child, &status, 0) < 0) {
        if (errno != EINTR) {
            return false;
        }
    }
    return WIFEXITED(status) && WEXITSTATUS(status) == 0;
}

}  // namespace

std::vector<GameProcess> scan_game_processes() {
    std::vector<GameProcess> games;
    std::error_code ec;
    for (const auto& entry : fs::directory_iterator("/proc", fs::directory_options::skip_permission_denied, ec)) {
        if (ec) {
            break;
        }
        const auto name = entry.path().filename().string();
        if (name.empty() || name.find_first_not_of("0123456789") != std::string::npos) {
            continue;
        }
        try {
            const auto pid_value = std::stol(name);
            if (pid_value <= 1) {
                continue;
            }
            if (auto process = inspect_process(static_cast<pid_t>(pid_value))) {
                games.push_back(std::move(*process));
            }
        } catch (...) {
            continue;
        }
    }
    return games;
}

bool tune_game_process(const GameProcess& process) {
    bool ok = true;

    if (::setpriority(PRIO_PROCESS, static_cast<id_t>(process.pid), kGamingNice) != 0 && errno != EACCES && errno != EPERM) {
        ok = false;
    }

#ifdef SYS_ioprio_set
    const int ioprio = (kIoPrioClassBestEffort << kIoPrioClassShift) | kGamingIoPriority;
    if (::syscall(SYS_ioprio_set, kIoPrioWhoProcess, process.pid, ioprio) != 0 && errno != EACCES && errno != EPERM) {
        ok = false;
    }
#endif

    return ok;
}

bool gaming_marker_present() {
    std::error_code ec;
    const fs::path run_user{"/run/user"};
    if (!fs::exists(run_user, ec)) {
        return false;
    }
    for (const auto& entry : fs::directory_iterator(run_user, fs::directory_options::skip_permission_denied, ec)) {
        if (ec) {
            return false;
        }
        if (fs::exists(entry.path() / "pulseos" / "gaming-active", ec) && !ec) {
            return true;
        }
        ec.clear();
    }
    return false;
}

std::optional<std::string> current_tuned_profile() {
    std::array<char, 256> buffer{};
    std::string output;
    FILE* pipe = ::popen("LC_ALL=C tuned-adm active 2>/dev/null", "r");
    if (pipe == nullptr) {
        return std::nullopt;
    }
    while (std::fgets(buffer.data(), static_cast<int>(buffer.size()), pipe) != nullptr) {
        output += buffer.data();
    }
    const int status = ::pclose(pipe);
    if (status == -1 || !WIFEXITED(status) || WEXITSTATUS(status) != 0) {
        return std::nullopt;
    }

    constexpr std::string_view prefix{"Current active profile: "};
    const auto start = output.find(prefix);
    if (start == std::string::npos) {
        return std::nullopt;
    }
    auto profile = output.substr(start + prefix.size());
    const auto newline = profile.find_first_of("\r\n");
    if (newline != std::string::npos) {
        profile.resize(newline);
    }
    return profile.empty() ? std::nullopt : std::optional<std::string>{profile};
}

bool set_tuned_profile(const std::string& profile) {
    if (profile.empty() || profile.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.") != std::string::npos) {
        return false;
    }
    return run_program("tuned-adm", {"profile", profile});
}

}  // namespace pulseos
