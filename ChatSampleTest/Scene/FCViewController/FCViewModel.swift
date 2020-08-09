//
//  FCViewModel.swift
//  ChatSampleTest
//
//  Created by tanaz on 5/20/1399 AP.
//  Copyright © 1399 ChatSampleTest. All rights reserved.
//

import Foundation
import UIKit

import Firebase

class FCViewModel {
    
    var _refHandle: DatabaseHandle!
    weak var vc: FCViewController!
    var ref: DatabaseReference!

    
    init(_ vc: FCViewController) {
        self.vc = vc
    }
    
    
    func configureDatabase() {
      ref = Database.database().reference()
      // Listen for new messages in the Firebase database
      _refHandle = self.ref.child("messages").observe(.childAdded, with: { [weak self] (snapshot) -> Void in
        guard let strongSelf = self else { return }
        
        strongSelf.vc.updateTableviewByDatabase(snapshot)
      })
    }
}
