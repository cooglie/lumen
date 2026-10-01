// aurora.cpp — Aurora Shader-Engine (DirectX 11) Implementation
#include "aurora.h"
#include <d3dcompiler.h>
#include <chrono>
#include <cstdio>

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "d3dcompiler.lib")
#pragma comment(lib, "dxgi.lib")

static const wchar_t* kOverlayClass = L"LumenAuroraOverlay";
static const wchar_t* kOverlayTitle = L"Lumen Aurora";

static double NowSeconds() {
    using namespace std::chrono;
    return duration<double>(steady_clock::now().time_since_epoch()).count();
}

AuroraRenderer::AuroraRenderer() {
    shaders_ = {
        { L"Nebula",          "nebula.hlsl" },
        { L"Aurora Borealis", "aurora.hlsl" },
        { L"Plasma Field",    "plasma.hlsl" }
    };
}

AuroraRenderer::~AuroraRenderer() { Shutdown(); }

// --- Overlay-Window: randlos, klick-durchlässig, hinter Desktop-Icons ---

static AuroraRenderer* gInstance = nullptr;

LRESULT CALLBACK AuroraRenderer::WndProcThunk(HWND h, UINT msg, WPARAM w, LPARAM l) {
    return DefWindowProc(h, msg, w, l);
}

bool AuroraRenderer::CreateOverlayWindow() {
    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = &AuroraRenderer::WndProcThunk;
    wc.hInstance = GetModuleHandle(nullptr);
    wc.lpszClassName = kOverlayClass;
    RegisterClassExW(&wc);

    int sw = GetSystemMetrics(SM_CXSCREEN);
    int sh = GetSystemMetrics(SM_CYSCREEN);

    // WS_EX_LAYERED + WS_EX_TRANSPARENT = klick-durchlässig.
    // WS_EX_TOOLWINDOW = kein Taskbar-Eintrag.
    hwnd_ = CreateWindowExW(
        WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE,
        kOverlayClass, kOverlayTitle,
        WS_POPUP,
        0, 0, sw, sh,
        nullptr, nullptr, GetModuleHandle(nullptr), nullptr);
    if (!hwnd_) return false;

    // Komplett transparente Layer (Zeichnung kommt via Swapchain direkt).
    SetLayeredWindowAttributes(hwnd_, 0, 255, LWA_ALPHA);

    // WorkerW-Trick: Fenster hinter die Desktop-Icons schieben, damit es wie
    // ein Wallpaper wirkt. SendMessage an Progman erzeugt einen WorkerW;
    // wir positionieren unser Fenster als Bottom und es bleibt klick-durchlässig.
    HWND progman = FindWindowW(L"Progman", nullptr);
    if (progman) {
        SendMessageTimeoutW(progman, 0x052C, 0, 0, SMTO_NORMAL, 1000, nullptr);
    }
    SetWindowPos(hwnd_, HWND_BOTTOM, 0, 0, sw, sh, SWP_NOACTIVATE | SWP_SHOWWINDOW);
    return true;
}

bool AuroraRenderer::CreateDeviceAndSwapchain() {
    DXGI_SWAP_CHAIN_DESC sc = {};
    sc.BufferCount = 2;
    sc.BufferDesc.Width  = GetSystemMetrics(SM_CXSCREEN);
    sc.BufferDesc.Height = GetSystemMetrics(SM_CYSCREEN);
    sc.BufferDesc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    sc.BufferDesc.RefreshRate.Numerator = 60;
    sc.BufferDesc.RefreshRate.Denominator = 1;
    sc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sc.OutputWindow = hwnd_;
    sc.SampleDesc.Count = 1;
    sc.Windowed = TRUE;
    sc.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;
    sc.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;

    UINT flags = 0;
#ifdef _DEBUG
    flags |= D3D11_CREATE_DEVICE_DEBUG;
#endif
    D3D_FEATURE_LEVEL fls[] = { D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_0 };
    HRESULT hr = D3D11CreateDeviceAndSwapChain(
        nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, flags,
        fls, 2, D3D11_SDK_VERSION, &sc, &swap_, &device_, nullptr, &ctx_);
    if (FAILED(hr)) {
        // Fallback ohne Debug-Flag.
        hr = D3D11CreateDeviceAndSwapChain(
            nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, 0,
            fls, 2, D3D11_SDK_VERSION, &sc, &swap_, &device_, nullptr, &ctx_);
        if (FAILED(hr)) return false;
    }

    ID3D11Texture2D* back = nullptr;
    swap_->GetBuffer(0, __uuidof(ID3D11Texture2D), (void**)&back);
    if (back) {
        device_->CreateRenderTargetView(back, nullptr, &rtv_);
        back->Release();
    }

    // Constant Buffer für die Zeit (ein float).
    D3D11_BUFFER_DESC bd = {};
    bd.ByteWidth = 16; // aufrundbar auf 16-Byte-Grenze
    bd.Usage = D3D11_USAGE_DYNAMIC;
    bd.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
    bd.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
    device_->CreateBuffer(&bd, nullptr, &timeCB_);
    return true;
}

bool AuroraRenderer::BuildPipeline(const std::string& file) {
    ReleasePipeline();
    if (!device_) return false;

    WCHAR path[MAX_PATH];
    GetModuleFileNameW(GetModuleHandle(nullptr), path, MAX_PATH);
    PathRemoveFileSpecW(path);
    std::wstring full = std::wstring(path) + L"\\shaders\\" + std::wstring(file.begin(), file.end());

    UINT cflags = D3DCOMPILE_OPTIMIZATION_LEVEL3;
    ID3DBlob* vsb = nullptr, * psb = nullptr, * err = nullptr;
    // Vertex-Shader aus common.hlsl (LumenVS).
    std::wstring cfull = std::wstring(path) + L"\\shaders\\common.hlsl";
    if (FAILED(D3DCompileFromFile(cfull.c_str(), nullptr, D3D_COMPILE_STANDARD_FILE_INCLUDE,
                                  "LumenVS", "vs_5_0", cflags, 0, &vsb, &err))) {
        if (err) { err->Release(); }
        return false;
    }
    if (FAILED(D3DCompileFromFile(full.c_str(), nullptr, D3D_COMPILE_STANDARD_FILE_INCLUDE,
                                  "PSMain", "ps_5_0", cflags, 0, &psb, &err))) {
        if (err) { err->Release(); }
        if (vsb) vsb->Release();
        return false;
    }
    device_->CreateVertexShader(vsb->GetBufferPointer(), vsb->GetBufferSize(), nullptr, &vs_);
    device_->CreatePixelShader(psb->GetBufferPointer(), psb->GetBufferSize(), nullptr, &ps_);
    if (vsb) vsb->Release();
    if (psb) psb->Release();
    return (vs_ && ps_);
}

void AuroraRenderer::ReleasePipeline() {
    if (vs_) { vs_->Release(); vs_ = nullptr; }
    if (ps_) { ps_->Release(); ps_ = nullptr; }
}

bool AuroraRenderer::Init() {
    gInstance = this;
    if (!CreateOverlayWindow()) return false;
    if (!CreateDeviceAndSwapChain()) return false;
    if (shaders_.empty()) return false;
    if (!BuildPipeline(shaders_[0].file)) return false;
    return true;
}

bool AuroraRenderer::SelectShader(const std::string& file) {
    bool ok = BuildPipeline(file);
    if (ok) {
        for (size_t i = 0; i < shaders_.size(); ++i) {
            if (shaders_[i].file == file) { activeIndex_ = (int)i; break; }
        }
    }
    return ok;
}

void AuroraRenderer::Start() {
    if (running_) return;
    running_ = true;
    startTime_ = NowSeconds();
    ShowWindow(hwnd_, SW_SHOWNOACTIVATE);
}

void AuroraRenderer::Stop() {
    running_ = false;
    ShowWindow(hwnd_, SW_HIDE);
}

void AuroraRenderer::Toggle() { running_ ? Stop() : Start(); }

void AuroraRenderer::RenderFrame() {
    if (!running_ || !ctx_ || !swap_ || !rtv_) return;

    float t = (float)(NowSeconds() - startTime_);
    D3D11_MAPPED_SUBRESOURCE mapped = {};
    if (SUCCEEDED(ctx_->Map(timeCB_, 0, D3D11_MAP_WRITE_DISCARD, 0, &mapped))) {
        memcpy(mapped.pData, &t, sizeof(float));
        ctx_->Unmap(timeCB_, 0);
    }

    float clear[4] = { 0, 0, 0, 1 };
    ctx_->ClearRenderTargetView(rtv_, clear);
    ctx_->OMSetRenderTargets(1, &rtv_, nullptr);

    D3D11_VIEWPORT vp = {};
    vp.Width = (float)GetSystemMetrics(SM_CXSCREEN);
    vp.Height = (float)GetSystemMetrics(SM_CYSCREEN);
    vp.MaxDepth = 1.0f;
    ctx_->RSSetViewports(1, &vp);

    ctx_->VSSetShader(vs_, nullptr, 0);
    ctx_->PSSetShader(ps_, nullptr, 0);
    ctx_->VSSetConstantBuffers(0, 1, &timeCB_);
    ctx_->PSSetConstantBuffers(0, 1, &timeCB_);
    ctx_->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    // Vollbild-Dreieck ohne Vertex-Buffer (SV_VertexID).
    ctx_->Draw(3, 0);

    swap_->Present(1, 0);
}

void AuroraRenderer::Shutdown() {
    ReleasePipeline();
    if (timeCB_) { timeCB_->Release(); timeCB_ = nullptr; }
    if (rtv_) { rtv_->Release(); rtv_ = nullptr; }
    if (swap_) { swap_->Release(); swap_ = nullptr; }
    if (ctx_) { ctx_->Release(); ctx_ = nullptr; }
    if (device_) { device_->Release(); device_ = nullptr; }
    if (hwnd_) { DestroyWindow(hwnd_); hwnd_ = nullptr; }
}
