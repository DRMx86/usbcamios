import SwiftUI

struct ContentView: View {
    @StateObject private var camera = CameraManager()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            if camera.authorized {
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()
            }

            VStack(spacing: 10) {
                Text(camera.status)
                    .font(.footnote)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                if camera.devices.count > 1 {
                    Picker("Camera", selection: Binding(
                        get: { camera.selectedID ?? "" },
                        set: { camera.select($0) }
                    )) {
                        ForEach(camera.devices, id: \.uniqueID) { device in
                            Text(device.localizedName).tag(device.uniqueID)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                }

                Button("Refresh cameras") { camera.refreshDevices() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.black.opacity(0.55))
            .cornerRadius(14)
            .padding()
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
    }
}
