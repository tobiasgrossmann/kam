import SwiftUI

struct ContentView: View {
    var body: some View {
        KamasutraCatalogView()
            .onAppear {
                print("ContentView appeared")
            }
    }
}
