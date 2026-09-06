#pragma once

#include <sys/types.h>

#include <optional>
#include <string>
#include <vector>

namespace pulseos {

struct GameProcess {
    pid_t pid{};
    uid_t uid{};
    std::string app_id;
    std::string command;
};

std::vector<GameProcess> scan_game_processes();
bool tune_game_process(const GameProcess& process);
bool gaming_marker_present();

std::optional<std::string> current_tuned_profile();
bool set_tuned_profile(const std::string& profile);

}  // namespace pulseos
