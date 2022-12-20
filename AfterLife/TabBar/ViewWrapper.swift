//
//  ViewWrapper.swift
//  SwiftUI_FullApp
//
//  Created by Hugues Capet on 07.11.22.
//

import Foundation
import SwiftUI

struct ViewWrapper: Identifiable {
    
    var id = UUID().uuidString
    var destinationView: AnyView
    var title: String
    
}
