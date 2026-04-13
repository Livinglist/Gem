//
//  HomeWidgetLiveActivity.swift
//  HomeWidget
//
//  Created by Jiaqi Fung on 4/13/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct HomeWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct HomeWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HomeWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension HomeWidgetAttributes {
    fileprivate static var preview: HomeWidgetAttributes {
        HomeWidgetAttributes(name: "World")
    }
}

extension HomeWidgetAttributes.ContentState {
    fileprivate static var smiley: HomeWidgetAttributes.ContentState {
        HomeWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: HomeWidgetAttributes.ContentState {
         HomeWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: HomeWidgetAttributes.preview) {
   HomeWidgetLiveActivity()
} contentStates: {
    HomeWidgetAttributes.ContentState.smiley
    HomeWidgetAttributes.ContentState.starEyes
}
