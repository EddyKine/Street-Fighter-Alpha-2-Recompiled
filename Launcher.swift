import SwiftUI
import AppKit
import GameController

struct LauncherConfig: Codable {
    var shaderPreset: String = "scanlines/scanline-fract.slangp"
}

final class LauncherState: ObservableObject {
    @Published var status = "LISTO PARA COMBATIR"
    @Published var controllers = GCController.controllers().map { $0.vendorName ?? "Mando" }
    @Published var selectedShader = "scanlines/scanline-fract.slangp"
    @Published var busy = false
    @Published var currentSection = "jugar"

    let root: URL
    let orange = Color(red: 1.0, green: 0.36, blue: 0.14)
    let gold = Color(red: 0.95, green: 0.78, blue: 0.20)
    let electricBlue = Color(red: 0.23, green: 0.52, blue: 1.00)

    init(root: URL) {
        self.root = root
        loadConfig()
    }

    var engine: URL { root.appendingPathComponent("Motor.app") }
    var userFolder: URL { root.appendingPathComponent("user") }
    var artURL: URL { root.appendingPathComponent("arte.png") }
    var logURL: URL { root.appendingPathComponent("motor.log") }
    var configURL: URL { root.appendingPathComponent("launcher_config.json") }

    func loadConfig() {
        if let data = try? Data(contentsOf: configURL), let cfg = try? JSONDecoder().decode(LauncherConfig.self, from: data) {
            selectedShader = cfg.shaderPreset
        }
    }

    func saveConfig() {
        let cfg = LauncherConfig(shaderPreset: selectedShader)
        if let data = try? JSONEncoder().encode(cfg) {
            try? data.write(to: configURL, options: [.atomic])
        }
    }

    func selectShader(_ value: String) {
        selectedShader = value
        saveConfig()
        status = value.isEmpty ? "Filtro original seleccionado" : "Preset seleccionado"
    }

    func refreshControllers() {
        controllers = GCController.controllers().map { $0.vendorName ?? "Mando" }
    }

    func launch(play: Bool) {
        guard !busy else { return }
        let exe = Bundle(url: engine)?.executableURL
        guard let exe else { status = "No se encuentra Motor.app"; return }
        let unified = exe.lastPathComponent.lowercased().contains("launcher")
        var args: [String] = []
        if play {
            args = unified ? ["--play", "sfa2"] : ["--play"]
            if !selectedShader.isEmpty {
                args += ["--shader", selectedShader]
            }
        } else {
            args = unified ? ["--page", "sfa2"] : []
        }
        let p = Process()
        p.executableURL = exe
        p.currentDirectoryURL = root
        p.arguments = args
        p.terminationHandler = { proc in
            DispatchQueue.main.async {
                self.busy = false
                self.status = proc.terminationStatus == 0 ? "LISTO PARA COMBATIR" : "Motor terminó con código \(proc.terminationStatus). Revisa el log."
            }
        }
        do {
            if !FileManager.default.fileExists(atPath: logURL.path) {
                FileManager.default.createFile(atPath: logURL.path, contents: nil)
            }
            let handle = try FileHandle(forWritingTo: logURL)
            try handle.seekToEnd()
            p.standardOutput = handle
            p.standardError = handle
            try p.run()
            busy = true
            status = play ? "MOTOR EN EJECUCIÓN" : "CONFIGURACIÓN DEL MOTOR ABIERTA"
        } catch {
            status = error.localizedDescription
        }
    }

    func open(_ url: URL) { NSWorkspace.shared.open(url) }
}

struct PanelCard<Content: View>: View {
    let title: String
    let system: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: system).foregroundColor(.white.opacity(0.85))
                Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
            }
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.07, green: 0.15, blue: 0.34), Color(red: 0.03, green: 0.08, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.18), lineWidth: 1))
        )
    }
}

struct SidebarButton: View {
    let icon: String
    let title: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 15, weight: .medium)).frame(width: 24)
                Text(title).font(.system(size: 14, weight: .medium))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(selected ? LinearGradient(colors: [Color(red: 0.75, green: 0.10, blue: 0.18), Color(red: 0.36, green: 0.05, blue: 0.14)], startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [Color.white.opacity(0.04), Color.white.opacity(0.02)], startPoint: .leading, endPoint: .trailing))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Color(red: 1.0, green: 0.50, blue: 0.34) : Color.white.opacity(0.08), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }.buttonStyle(.plain)
    }
}

struct MainView: View {
    @StateObject private var state = LauncherState(root: Bundle.main.bundleURL.deletingLastPathComponent())

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.03, green: 0.06, blue: 0.16), Color(red: 0.02, green: 0.03, blue: 0.09)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.circle.fill").foregroundColor(state.orange)
                    Text("Street Fighter Alpha 2 Recompiled").font(.system(size: 17, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.04))

                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        GeometryReader { geo in
                            if let img = NSImage(contentsOf: state.artURL) {
                                Image(nsImage: img).resizable().scaledToFit()
                                    .frame(width: geo.size.width - 24, height: geo.size.height - 12)
                                    .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                                    .background(Color(red: 0.05, green: 0.08, blue: 0.18))
                                    .clipped()
                            } else {
                                Color.indigo
                            }
                        }
                        .frame(maxHeight: .infinity)
                        VStack(alignment: .leading, spacing: 6) {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                            SidebarButton(icon: "gamecontroller.fill", title: "Jugar", selected: state.currentSection == "jugar") { state.currentSection = "jugar" }
                            SidebarButton(icon: "gearshape.fill", title: "Configuración", selected: state.currentSection == "config") { state.currentSection = "config" }
                            SidebarButton(icon: "gamecontroller", title: "Controles", selected: state.currentSection == "controls") { state.currentSection = "controls" }
                            SidebarButton(icon: "figure.strengthtraining.traditional", title: "Entrenamiento", selected: state.currentSection == "training") { state.currentSection = "training" }
                            SidebarButton(icon: "star", title: "Extras", selected: state.currentSection == "extras") { state.currentSection = "extras" }
                            SidebarButton(icon: "info.circle", title: "Créditos", selected: state.currentSection == "credits") { state.currentSection = "credits" }
                            }
                            Label("APPLE SILICON · ARM64", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 11, weight: .bold)).foregroundColor(.green).padding(8)
                        }.padding(12).background(Color(red: 0.05, green: 0.08, blue: 0.18))
                    }.frame(width: 690)

                    // RIGHT main
                    VStack(alignment: .leading, spacing: 12) {
                      ScrollView {
                       VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Street Fighter")
                                    .font(.system(size: 34, weight: .heavy, design: .default))
                                    .foregroundStyle(LinearGradient(colors: [Color(red: 1.0, green: 0.93, blue: 0.55), Color(red: 1.0, green: 0.37, blue: 0.18)], startPoint: .leading, endPoint: .trailing))
                                    .shadow(color: .black.opacity(0.35), radius: 3)
                                HStack(alignment: .bottom, spacing: 8) {
                                    Text("ALPHA")
                                        .font(.system(size: 42, weight: .heavy, design: .default))
                                        .foregroundColor(.white)
                                    Text("2")
                                        .font(.system(size: 54, weight: .heavy, design: .default))
                                        .foregroundColor(.red)
                                }
                                Text("RECOMPILED")
                                    .font(.system(size: 21, weight: .heavy, design: .default))
                                    .foregroundColor(state.gold)
                                Text("CPS-2  •  Native ARM64  •  macOS")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            Spacer()
                        }

                        if state.currentSection == "jugar" || state.currentSection == "config" {
                            VStack(spacing: 12) {
                                PanelCard(title: "Gráficos y pantalla", system: "display") {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Picker("Filtro de pantalla", selection: Binding(get: { state.selectedShader }, set: { state.selectShader($0) })) {
                                            Text("Original").tag("")
                                            Text("Scanlines Suaves").tag("scanlines/scanline-fract.slangp")
                                            Text("Scanlines Arcade").tag("pixel-art-scaling/sharp-bilinear-scanlines.slangp")
                                            Text("CRT Light").tag("crt/zfast-crt.slangp")
                                        }.pickerStyle(.menu).disabled(state.busy)
                                        Divider()
                                        HStack {
                                            Text("Resolución y pantalla").font(.system(size: 13))
                                            Spacer()
                                            Button("Configurar…") { state.launch(play: false) }.disabled(state.busy)
                                        }
                                        Text("El filtro elegido se utiliza al pulsar Jugar.").font(.caption).foregroundColor(.secondary)
                                    }
                                }
                                PanelCard(title: "Controles", system: "gamecontroller") {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(state.controllers.isEmpty ? "Sin mando detectado" : state.controllers.joined(separator: " • "))
                                            Text("Arcade · 6 botones").font(.caption).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Button("Actualizar") { state.refreshControllers() }
                                        Button("Configurar…") { state.launch(play: false) }.disabled(state.busy)
                                    }
                                }
                                PanelCard(title: "Modo entrenamiento", system: "figure.strengthtraining.traditional") {
                                    HStack {
                                        Text("Opciones de práctica del motor").font(.system(size: 13))
                                        Spacer()
                                        Button("Opciones…") { state.launch(play: false) }.disabled(state.busy)
                                    }
                                }
                            }
                            Button(action: { state.launch(play: true) }) {
                                HStack {
                                    Image(systemName: "play.fill").font(.title2)
                                    Text("JUGAR")
                                        .font(.system(size: 23, weight: .heavy, design: .default))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 36)
                                .padding(.vertical, 12)
                                .background(LinearGradient(colors: [Color(red: 0.88, green: 0.15, blue: 0.20), Color(red: 0.78, green: 0.35, blue: 0.05)], startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(state.gold, lineWidth: 1.5))
                                .shadow(color: Color(red: 0.88, green: 0.15, blue: 0.20).opacity(0.35), radius: 5, y: 3)
                            }
                            .buttonStyle(.plain)
                            .disabled(state.busy)
                        } else if state.currentSection == "controls" {
                            PanelCard(title: "Controles Arcade", system: "gamecontroller.fill") {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(state.controllers.isEmpty ? "No hay mandos detectados por macOS" : state.controllers.joined(separator: " • "))
                                        .foregroundColor(state.gold)
                                    Group {
                                        Text("X = Puño débil")
                                        Text("Y = Puño medio")
                                        Text("RB = Puño fuerte")
                                        Text("A = Patada débil")
                                        Text("B = Patada media")
                                        Text("RT = Patada fuerte")
                                    }
                                    .foregroundColor(.white.opacity(0.9))
                                    HStack(spacing: 12) {
                                        Button("Abrir configuración del motor") { state.launch(play: false) }
                                        Button("Abrir datos portable") { state.open(state.userFolder) }
                                    }
                                }
                            }
                        } else if state.currentSection == "training" {
                            PanelCard(title: "Entrenamiento", system: "figure.strengthtraining.traditional") {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Este port conserva el training mode propio de CPS2Recomp.")
                                    Text("Para opciones detalladas, memoria del tablero y perfiles, usa el panel nativo del motor.")
                                        .foregroundColor(.white.opacity(0.78))
                                    Button("Abrir opciones del motor") { state.launch(play: false) }
                                }
                            }
                        } else if state.currentSection == "extras" {
                            PanelCard(title: "Extras", system: "star.fill") {
                                VStack(alignment: .leading, spacing: 12) {
                                    Button("Abrir carpeta portable") { state.open(state.root) }
                                    Button("Abrir carpeta user") { state.open(state.userFolder) }
                                    Button("Ver motor.log") { state.open(state.logURL) }
                                    Button("Abrir Motor.app") { state.open(state.engine) }
                                }
                            }
                        } else {
                            PanelCard(title: "Créditos", system: "info.circle.fill") {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Street Fighter Alpha 2 Recompiled")
                                    Text("Lanzador temático portable para macOS ARM64")
                                    Text("Base técnica: CPS2Recomp + corrección de shaders/scanlines")
                                        .foregroundColor(.white.opacity(0.78))
                                    Text("Quinta Fotográfica / Proyecto local")
                                        .foregroundColor(state.gold)
                                }
                            }
                        }
                       }.frame(maxWidth: .infinity, alignment: .leading)
                      }
                        HStack {
                            Circle().fill(state.busy ? state.orange : .green).frame(width: 9, height: 9)
                            Text(state.status)
                            Spacer()
                            Text(state.controllers.isEmpty ? "MANDO NO DETECTADO" : "MANDO CONECTADO")
                        }
                        .font(.system(size: 11, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.75))
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
        .frame(minWidth: 1240, minHeight: 740)
        .onReceive(NotificationCenter.default.publisher(for: .GCControllerDidConnect)) { _ in state.refreshControllers() }
        .onReceive(NotificationCenter.default.publisher(for: .GCControllerDidDisconnect)) { _ in state.refreshControllers() }
    }
}

@main struct SFA2ArcadeLauncherApp: App {
    var body: some Scene {
        WindowGroup {
            MainView().preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1360, height: 820)
    }
}
