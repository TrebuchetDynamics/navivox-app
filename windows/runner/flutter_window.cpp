#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <optional>

#include "desktop_host_commands.h"
#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate() || !CreateApplicationMenu()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  host_command_channel_ = std::make_unique<
      flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      desktop_host_commands::kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  host_command_channel_.reset();
  flutter_controller_.reset();

  if (application_menu_) {
    if (GetHandle()) {
      SetMenu(GetHandle(), nullptr);
    }
    DestroyMenu(application_menu_);
    application_menu_ = nullptr;
  }

  Win32Window::OnDestroy();
}

bool FlutterWindow::CreateApplicationMenu() {
  HMENU menu_bar = CreateMenu();
  HMENU application_menu = CreatePopupMenu();
  HMENU window_menu = CreatePopupMenu();
  HMENU view_menu = CreatePopupMenu();
  if (!menu_bar || !application_menu || !window_menu || !view_menu) {
    if (menu_bar) {
      DestroyMenu(menu_bar);
    }
    if (application_menu) {
      DestroyMenu(application_menu);
    }
    if (window_menu) {
      DestroyMenu(window_menu);
    }
    if (view_menu) {
      DestroyMenu(view_menu);
    }
    return false;
  }

  if (!AppendMenuW(application_menu, MF_STRING,
                   desktop_host_commands::kOpenSettingsCommand,
                   L"Settings\u2026\tCtrl+,") ||
      !AppendMenuW(application_menu, MF_SEPARATOR, 0, nullptr) ||
      !AppendMenuW(application_menu, MF_STRING,
                   desktop_host_commands::kShowAboutCommand,
                   L"About Hermes Wing") ||
      !AppendMenuW(window_menu, MF_STRING,
                   desktop_host_commands::kMinimizeWindowCommand,
                   L"Minimize") ||
      !AppendMenuW(window_menu, MF_STRING,
                   desktop_host_commands::kToggleMaximizeWindowCommand,
                   L"Maximize / Restore") ||
      !AppendMenuW(view_menu, MF_STRING,
                   desktop_host_commands::kToggleFullScreenCommand,
                   L"Full Screen\tF11")) {
    DestroyMenu(menu_bar);
    DestroyMenu(application_menu);
    DestroyMenu(window_menu);
    DestroyMenu(view_menu);
    return false;
  }

  if (!AppendMenuW(menu_bar, MF_POPUP,
                   reinterpret_cast<UINT_PTR>(application_menu),
                   L"Hermes Wing")) {
    DestroyMenu(menu_bar);
    DestroyMenu(application_menu);
    DestroyMenu(window_menu);
    DestroyMenu(view_menu);
    return false;
  }
  if (!AppendMenuW(menu_bar, MF_POPUP,
                   reinterpret_cast<UINT_PTR>(window_menu), L"Window")) {
    DestroyMenu(menu_bar);
    DestroyMenu(window_menu);
    DestroyMenu(view_menu);
    return false;
  }
  if (!AppendMenuW(menu_bar, MF_POPUP,
                   reinterpret_cast<UINT_PTR>(view_menu), L"View")) {
    DestroyMenu(menu_bar);
    DestroyMenu(view_menu);
    return false;
  }

  if (!SetMenu(GetHandle(), menu_bar)) {
    DestroyMenu(menu_bar);
    return false;
  }

  application_menu_ = menu_bar;
  DrawMenuBar(GetHandle());
  return true;
}

void FlutterWindow::OpenSettings() {
  if (!host_command_channel_) {
    return;
  }
  host_command_channel_->InvokeMethod(desktop_host_commands::kOpenSettingsMethod,
                                      nullptr);
}

void FlutterWindow::ToggleFullScreen() {
  HWND window = GetHandle();
  if (!window) {
    return;
  }

  if (!is_fullscreen_) {
    WINDOWPLACEMENT placement{};
    placement.length = sizeof(WINDOWPLACEMENT);
    MONITORINFO monitor_info{};
    monitor_info.cbSize = sizeof(MONITORINFO);
    if (!GetWindowPlacement(window, &placement) ||
        !GetMonitorInfo(MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST),
                        &monitor_info)) {
      return;
    }

    SetLastError(ERROR_SUCCESS);
    LONG_PTR style = GetWindowLongPtr(window, GWL_STYLE);
    if (style == 0 && GetLastError() != ERROR_SUCCESS) {
      return;
    }

    windowed_placement_ = placement;
    windowed_style_ = style;
    SetWindowLongPtr(window, GWL_STYLE, style & ~WS_OVERLAPPEDWINDOW);
    const RECT& bounds = monitor_info.rcMonitor;
    if (!SetWindowPos(window, HWND_TOP, bounds.left, bounds.top,
                      bounds.right - bounds.left, bounds.bottom - bounds.top,
                      SWP_NOOWNERZORDER | SWP_FRAMECHANGED)) {
      SetWindowLongPtr(window, GWL_STYLE, style);
      return;
    }
    is_fullscreen_ = true;
    return;
  }

  SetWindowLongPtr(window, GWL_STYLE, windowed_style_);
  SetWindowPlacement(window, &windowed_placement_);
  SetWindowPos(window, nullptr, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER |
                   SWP_FRAMECHANGED);
  is_fullscreen_ = false;
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_COMMAND) {
    switch (LOWORD(wparam)) {
      case desktop_host_commands::kOpenSettingsCommand:
        OpenSettings();
        return 0;
      case desktop_host_commands::kShowAboutCommand:
        MessageBoxW(hwnd,
                    L"Hermes Wing\n\nA cross-platform client for your Hermes "
                    L"Agent.",
                    L"About Hermes Wing", MB_OK | MB_ICONINFORMATION);
        return 0;
      case desktop_host_commands::kMinimizeWindowCommand:
        ShowWindow(hwnd, SW_MINIMIZE);
        return 0;
      case desktop_host_commands::kToggleMaximizeWindowCommand:
        ShowWindow(hwnd, IsZoomed(hwnd) ? SW_RESTORE : SW_MAXIMIZE);
        return 0;
      case desktop_host_commands::kToggleFullScreenCommand:
        ToggleFullScreen();
        return 0;
    }
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
