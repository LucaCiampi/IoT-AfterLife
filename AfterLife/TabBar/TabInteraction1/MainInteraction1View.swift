//
//  MainCircleView.swift
//  SwiftUI_FullApp
//
//  Created by Hugues Capet on 07.11.22.
//

import SwiftUI

struct MainInteraction1View: View {
    
    @EnvironmentObject var bleInterface: BLEObservable
    
    var body: some View {
        VStack {
            
            Text("coucou")
        }
        .padding()
    }
}

struct MainInteraction1View_Previews: PreviewProvider {
    static var previews: some View {
        MainInteraction1View()
    }
}
