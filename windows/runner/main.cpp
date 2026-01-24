#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <memory>
#include <vector>
#include <string>

#include "flutter_window.h"
#include "utils.h"

/// ─────────────────────────────────────────
/// 🖨️ IMPRIMIR ESC/POS RAW (AUTO-DETECTA IMPRESORA)
/// ─────────────────────────────────────────
bool PrintRaw(const std::vector<uint8_t>& data, std::string& error) {
    DWORD needed = 0;

    // Obtener nombre de impresora por defecto
    GetDefaultPrinter(nullptr, &needed);
    if (needed == 0) {
        error = "No hay impresora configurada en Windows";
        return false;
    }

    std::wstring printerName(needed, L'\0');
    if (!GetDefaultPrinter(&printerName[0], &needed)) {
        error = "No se pudo obtener la impresora por defecto";
        return false;
    }

    HANDLE hPrinter;
    if (!OpenPrinter(printerName.data(), &hPrinter, NULL)) {
        error = "No se pudo abrir la impresora (¿apagada?)";
        return false;
    }

    DOC_INFO_1 docInfo;
    docInfo.pDocName = (LPWSTR)L"ESC POS";
    docInfo.pOutputFile = NULL;
    docInfo.pDatatype = (LPWSTR)L"RAW";

    if (!StartDocPrinter(hPrinter, 1, (LPBYTE)&docInfo)) {
        error = "No se pudo iniciar el documento de impresión";
        ClosePrinter(hPrinter);
        return false;
    }

    if (!StartPagePrinter(hPrinter)) {
        error = "No se pudo iniciar la página";
        EndDocPrinter(hPrinter);
        ClosePrinter(hPrinter);
        return false;
    }

    DWORD written = 0;
    if (!WritePrinter(
            hPrinter,
            (LPVOID)data.data(),
            static_cast<DWORD>(data.size()),
            &written)) {
        error = "Error al escribir en la impresora (¿apagada o sin papel?)";
        EndPagePrinter(hPrinter);
        EndDocPrinter(hPrinter);
        ClosePrinter(hPrinter);
        return false;
    }

    EndPagePrinter(hPrinter);
    EndDocPrinter(hPrinter);
    ClosePrinter(hPrinter);

    return true;
}

/// ─────────────────────────────────────────
/// 🚀 MAIN
/// ─────────────────────────────────────────
int APIENTRY wWinMain(_In_ HINSTANCE instance,
        _In_opt_ HINSTANCE prev,
        _In_ wchar_t* command_line,
        _In_ int show_command) {
// Consola para debug
if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
CreateAndAttachConsole();
}

::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

flutter::DartProject project(L"data");

std::vector<std::string> command_line_arguments =
        GetCommandLineArguments();
project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

FlutterWindow window(project);
Win32Window::Point origin(10, 10);
Win32Window::Size size(1280, 720);

if (!window.Create(L"panaderia_nicol_pos", origin, size)) {
return EXIT_FAILURE;
}

window.SetQuitOnClose(true);

// ─────────────────────────────────────────
// 🔗 METHOD CHANNEL (AQUÍ VA, SOLO AQUÍ)
// ─────────────────────────────────────────
auto* controller = window.GetFlutterController();

if (controller) {
auto messenger = controller->engine()->messenger();

auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
                messenger,
                        "escpos_usb",
                        &flutter::StandardMethodCodec::GetInstance());

channel->SetMethodCallHandler(
[](const flutter::MethodCall<flutter::EncodableValue>& call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

if (call.method_name() == "printEscPos") {
const auto* data =
        std::get_if<std::vector<uint8_t>>(call.arguments());

if (!data) {
result->Error("INVALID_DATA", "Datos inválidos");
return;
}

std::string error;
if (!PrintRaw(*data, error)) {
result->Error("PRINT_ERROR", error);
return;
}

result->Success();
} else {
result->NotImplemented();
}
});
}

// ─────────────────────────────────────────
// 🪟 LOOP WINDOWS
// ─────────────────────────────────────────
MSG msg;
while (::GetMessage(&msg, nullptr, 0, 0)) {
::TranslateMessage(&msg);
::DispatchMessage(&msg);
}

::CoUninitialize();
return EXIT_SUCCESS;
}