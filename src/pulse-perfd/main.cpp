#include "pulseos/process.hpp"

#include <syslog.h>

#include <atomic>
#include <chrono>
#include <csignal>
#include <filesystem>
#include <fstream>
#include <string>
#include <thread>
#include <unordered_set>

namespace fs = std::filesystem;
using namespace std::chrono_literals;

namespace {

std::atomic_bool running{true};
constexpr auto kPollInterval = 1s;
constexpr auto kExitHysteresis = 8s;
const fs::path kStateDir{"/run/pulseos"};
const fs::path kPreviousProfile{kStateDir / "previous-tuned-profile"};

void handle_signal(int) {
    running.store(false);
}

void save_previous_profile(const std::string& profile) {
    std::error_code ec;
    fs::create_directories(kStateDir, ec);
    std::ofstream out(kPreviousProfile, std::ios::trunc);
    if (out) {
        out << profile << '\n';
    }
}

std::string load_previous_profile() {
    std::ifstream in(kPreviousProfile);
    std::string profile;
    std::getline(in, profile);
    return profile.empty() ? "balanced" : profile;
}

void clear_previous_profile() {
    std::error_code ec;
    fs::remove(kPreviousProfile, ec);
}

void enter_gaming_mode() {
    if (const auto current = pulseos::current_tuned_profile()) {
        save_previous_profile(*current);
    }
    if (pulseos::set_tuned_profile("latency-performance")) {
        ::syslog(LOG_NOTICE, "gaming policy active: TuneD latency-performance");
    } else {
        ::syslog(LOG_WARNING, "unable to activate TuneD latency-performance; continuing with per-process tuning");
    }
}

void leave_gaming_mode() {
    const auto previous = load_previous_profile();
    if (!pulseos::set_tuned_profile(previous) && previous != "balanced") {
        pulseos::set_tuned_profile("balanced");
    }
    clear_previous_profile();
    ::syslog(LOG_NOTICE, "gaming policy inactive: previous TuneD profile restored");
}

}  // namespace

int main() {
    ::openlog("pulse-perfd", LOG_PID | LOG_NDELAY, LOG_DAEMON);
    std::signal(SIGINT, handle_signal);
    std::signal(SIGTERM, handle_signal);

    bool gaming_active = false;
    auto last_game_seen = std::chrono::steady_clock::now() - kExitHysteresis;
    std::unordered_set<int> tuned_pids;

    ::syslog(LOG_NOTICE, "PulseOS native performance daemon started");

    while (running.load()) {
        const auto games = pulseos::scan_game_processes();
        const bool marker = pulseos::gaming_marker_present();
        const auto now = std::chrono::steady_clock::now();

        if (!games.empty() || marker) {
            last_game_seen = now;
            if (!gaming_active) {
                enter_gaming_mode();
                gaming_active = true;
            }

            std::unordered_set<int> alive;
            for (const auto& game : games) {
                alive.insert(game.pid);
                if (!tuned_pids.contains(game.pid)) {
                    if (pulseos::tune_game_process(game)) {
                        ::syslog(LOG_INFO, "tuned game pid=%d appid=%s command=%s",
                                 game.pid, game.app_id.c_str(), game.command.c_str());
                    } else {
                        ::syslog(LOG_WARNING, "partial tuning failure pid=%d appid=%s",
                                 game.pid, game.app_id.c_str());
                    }
                }
            }
            tuned_pids = std::move(alive);
        } else if (gaming_active && now - last_game_seen >= kExitHysteresis) {
            leave_gaming_mode();
            gaming_active = false;
            tuned_pids.clear();
        }

        std::this_thread::sleep_for(kPollInterval);
    }

    if (gaming_active) {
        leave_gaming_mode();
    }
    ::syslog(LOG_NOTICE, "PulseOS native performance daemon stopped");
    ::closelog();
    return 0;
}
