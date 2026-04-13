//
//  HomeWidgetBundle.swift
//  HomeWidget
//
//  Created by Jiaqi Fung on 4/13/26.
//

import WidgetKit
import SwiftUI

@main
struct HomeWidgetBundle: WidgetBundle {
    var body: some Widget {
        HomeWidget()
        HomeWidgetControl()
        HomeWidgetLiveActivity()
    }
}
