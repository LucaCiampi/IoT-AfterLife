//
//  SinglePeripheralView.swift
//  AfterLife
//
//  Created by Hugues Capet on 08.11.22.
//

import SwiftUI

struct SinglePeripheralView: View {
    
    var periphName: String = ""
    
    var body: some View {
        Text(periphName)
    }
}

struct SinglePeripheralView_Previews: PreviewProvider {
    static var previews: some View {
        SinglePeripheralView()
    }
}
