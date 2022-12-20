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
            
            FilledLineChart(chartData: LineChartData(dataSets: LineDataSet(dataPoints: bleInterface.points)))
            Button("Stop") {
                bleInterface.sendMessage(message: "stopAccelero")
            }.disabled(bleInterface.hasLessThanHundredPoints)
        }
        .padding()
        .onAppear(perform: bleInterface.listenForAccelerometer)
    }
}

struct MainInteraction1View_Previews: PreviewProvider {
    static var previews: some View {
        MainInteraction1View()
    }
}
