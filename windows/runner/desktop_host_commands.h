#ifndef RUNNER_DESKTOP_HOST_COMMANDS_H_
#define RUNNER_DESKTOP_HOST_COMMANDS_H_

#include <windows.h>

namespace desktop_host_commands {

constexpr WORD kOpenSettingsCommand = 0x1001;
constexpr WORD kShowAboutCommand = 0x1002;
constexpr WORD kMinimizeWindowCommand = 0x1003;
constexpr WORD kToggleMaximizeWindowCommand = 0x1004;
constexpr WORD kToggleFullScreenCommand = 0x1005;
constexpr char kChannelName[] =
    "com.trebuchetdynamics.hermes.wing/desktop_host_commands";
constexpr char kOpenSettingsMethod[] = "openSettings";

}  // namespace desktop_host_commands

#endif  // RUNNER_DESKTOP_HOST_COMMANDS_H_
