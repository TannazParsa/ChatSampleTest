//
//  ClientTableViewCell.swift
//  ChatSampleTest
//
//  Created by tanaz on 5/20/1399 AP.
//  Copyright © 1399 ChatSampleTest. All rights reserved.
//

import UIKit

class ClientTableViewCell: UITableViewCell {

    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var lblUserMessage: UILabel!
    
    
    func config(image: UIImage, txt: String) {
        imgUser.image = image
        lblUserMessage.text = txt
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
