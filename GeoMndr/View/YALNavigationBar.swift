import UIKit

let defaultHeight : CGFloat = 65.0

class YALNavigationBar: UINavigationBar {
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var amendedSize = super.sizeThatFits(size)
        amendedSize.height = defaultHeight
        return amendedSize;
    }
}

