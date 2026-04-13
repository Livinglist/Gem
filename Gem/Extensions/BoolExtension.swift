import Foundation
import UIKit

extension Bool {
     static var iOS16: Bool {
         guard #available(iOS 16.0, *) else {
             return false
         }

         return true
     }
 }
