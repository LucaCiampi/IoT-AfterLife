//
//  SingleHistoryElement.swift
//  AfterLife
//
//  Created by Hugues Capet on 08.11.22.
//

import SwiftUI

struct SingleHistoryView: View {
    var name: String = ""
    
    var body: some View {
        Text(self.name)
            .padding()
    }
}

struct SingleHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        SingleHistoryView()
    }
}
