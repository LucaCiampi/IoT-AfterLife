//
//  MainCircleView.swift
//  SwiftUI_FullApp
//
//  Created by Hugues Capet on 07.11.22.
//

import SwiftUI

struct HistoryListElement: Identifiable, Equatable {
    var id = UUID().uuidString
    var text: String
}

struct MainInteraction2View: View {
    
    @EnvironmentObject var bleInterface: BLEObservable
    
    @State var connectionString = "No device connected"
    @State var scanButtonString = "Start scan"
    @State var isScanningDevices = false
    @State var isShowingDetailView = false
    
    var spheroInteraction2Name = "SB-5D1C"
    
    var body: some View {
        VStack {
            Text(connectionString)
            Button("Connexion sphero") {
                SharedToyBox.instance.searchForBoltsNamed([spheroInteraction2Name]) { err in
                    if err == nil {
                        self.connectionString = "Connected to " + spheroInteraction2Name
                    }
                }
            }
        }
        .padding()
    }
}


struct MainInteraction2View_Previews: PreviewProvider {
    static var previews: some View {
        MainInteraction2View()
    }
}
