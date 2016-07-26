//
//  Colour.swift
//  Skedule
//
//  Created by Greg Omelaenko on 6/02/2016.
//  Copyright © 2016 Greg Omelaenko. All rights reserved.
//

import UIKit

typealias UIColour = UIColor

extension UIColour {

	convenience init(hex c: UInt, alpha: CGFloat = 1) {
		self.init(
			red:	CGFloat((c & 0xff0000) >> 16) / 255.0,
			green:	CGFloat((c & 0x00ff00) >> 8) / 255.0,
			blue:	CGFloat(c & 0x0000ff) / 255.0,
			alpha:	alpha
		)
	}

    var hex: UInt {
        var r = 0 as CGFloat, g = r, b = r, a = r
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (UInt(r * 255) << 16) | (UInt(g * 255) << 8) | UInt(b * 255)
    }
	
	func colourByScalingParameters(brightness bs: CGFloat = 1, saturation ss: CGFloat = 1) -> UIColour {
		var h = 0 as CGFloat, s = h, b = h, a = h
		getHue(&h, saturation: &s, brightness: &b, alpha: &a)
		return UIColour(hue: h, saturation: s * ss, brightness: b * bs, alpha: a)
	}
	
	func darkerColour() -> UIColour {
		return colourByScalingParameters(brightness: 0.7)
	}
	
	func lighterColour() -> UIColour {
		return colourByScalingParameters(brightness: 1.3)
	}
	
	func toRGBAString() -> String {
		var r = 0 as CGFloat, g = r, b = r, a = r
		getRed(&r, green: &g, blue: &b, alpha: &a)
		return "rgba(\(Int(r * 255)), \(Int(g * 255)), \(Int(b * 255)), \(a))"
	}
	
}
