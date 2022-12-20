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
    
    var body: some View {
        VStack {
            Text("Historique")
            List(bleInterface.history.reversed()) { historyElement in
                SingleHistoryView(name: historyElement.text)
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
