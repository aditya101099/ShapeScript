//
//  SVGPath.swift
//  ShapeScript
//
//  Created by Nick Lockwood on 27/09/2021.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

import Foundation

struct SVGPath: Hashable {
    var commands: [SVGCommand]

    init(commands: [SVGCommand]) {
        self.commands = commands
    }

    init(_ string: String) throws {
        var token: UnicodeScalar = " "
        var commands = [SVGCommand]()
        var numbers = ArraySlice<Double>()
        var number = ""
        var isRelative = false

        func assertArgs(_ count: Int) throws -> [Double] {
            if numbers.count < count {
                throw SVGErrorType
                    .missingArgument(for: String(token), expected: count)
            } else if !numbers.count.isMultiple(of: count) {
                throw SVGErrorType
                    .unexpectedArgument(for: String(token), expected: count)
            }
            defer { numbers.removeFirst(count) }
            return Array(numbers.prefix(count))
        }

        func moveTo() throws -> SVGCommand {
            let numbers = try assertArgs(2)
            return .moveTo(SVGPoint(x: numbers[0], y: -numbers[1]))
        }

        func lineTo() throws -> SVGCommand {
            let numbers = try assertArgs(2)
            return .lineTo(SVGPoint(x: numbers[0], y: -numbers[1]))
        }

        func lineToVertical() throws -> SVGCommand {
            let numbers = try assertArgs(1)
            return .lineTo(SVGPoint(
                x: isRelative ? 0 : (commands.last?.point.x ?? 0),
                y: -numbers[0]
            ))
        }

        func lineToHorizontal() throws -> SVGCommand {
            let numbers = try assertArgs(1)
            return .lineTo(SVGPoint(
                x: numbers[0],
                y: isRelative ? 0 : (commands.last?.point.y ?? 0)
            ))
        }

        func quadCurve() throws -> SVGCommand {
            let numbers = try assertArgs(4)
            return .quadratic(
                SVGPoint(x: numbers[0], y: -numbers[1]),
                SVGPoint(x: numbers[2], y: -numbers[3])
            )
        }

        func quadTo() throws -> SVGCommand {
            let numbers = try assertArgs(2)
            var lastControl = commands.last?.control1 ?? .zero
            let lastPoint = commands.last?.point ?? .zero
            if case .quadratic? = commands.last {} else {
                lastControl = lastPoint
            }
            var control = lastPoint - lastControl
            if !isRelative {
                control = control + lastPoint
            }
            return .quadratic(control, SVGPoint(x: numbers[0], y: -numbers[1]))
        }

        func cubicCurve() throws -> SVGCommand {
            let numbers = try assertArgs(6)
            return .cubic(
                SVGPoint(x: numbers[0], y: -numbers[1]),
                SVGPoint(x: numbers[2], y: -numbers[3]),
                SVGPoint(x: numbers[4], y: -numbers[5])
            )
        }

        func cubicTo() throws -> SVGCommand {
            let numbers = try assertArgs(4)
            var lastControl = commands.last?.control2 ?? .zero
            let lastPoint = commands.last?.point ?? .zero
            if case .cubic? = commands.last {} else {
                lastControl = lastPoint
            }
            var control = lastPoint - lastControl
            if !isRelative {
                control = control + lastPoint
            }
            return .cubic(
                control,
                SVGPoint(x: numbers[0], y: -numbers[1]),
                SVGPoint(x: numbers[2], y: -numbers[3])
            )
        }

        func arc() throws -> SVGCommand {
            let numbers = try assertArgs(7)
            return .arc(SVGArc(
                radius: SVGPoint(x: numbers[0], y: numbers[1]),
                rotation: numbers[2] * .pi / 180,
                largeArc: numbers[3] != 0,
                sweep: numbers[4] != 0,
                end: SVGPoint(x: numbers[5], y: -numbers[6])
            ))
        }

        func end() throws -> SVGCommand {
            _ = try assertArgs(0)
            return .end
        }

        func processNumber() throws {
            if number.isEmpty {
                return
            }
            if let double = Double(number) {
                numbers.append(double)
                number = ""
                return
            }
            throw SVGErrorType.unexpectedToken(number)
        }

        func appendCommand(_ command: SVGCommand) {
            let last = isRelative ? commands.last : nil
            commands.append(command.relative(to: last))
        }

        func processCommand() throws {
            let command: SVGCommand
            switch token {
            case "m", "M":
                command = try moveTo()
                if !numbers.isEmpty {
                    appendCommand(command)
                    token = UnicodeScalar(token.value - 1)!
                    return try processCommand()
                }
            case "l", "L": command = try lineTo()
            case "v", "V": command = try lineToVertical()
            case "h", "H": command = try lineToHorizontal()
            case "q", "Q": command = try quadCurve()
            case "t", "T": command = try quadTo()
            case "c", "C": command = try cubicCurve()
            case "s", "S": command = try cubicTo()
            case "a", "A": command = try arc()
            case "z", "Z": command = try end()
            case " ": return
            default: throw SVGErrorType.unexpectedToken(String(token))
            }
            appendCommand(command)
            if !numbers.isEmpty {
                try processCommand()
            }
        }

        for char in string.unicodeScalars {
            switch char {
            case "0" ... "9", "E", "e", "+":
                number.append(Character(char))
            case ".":
                if number.contains(".") {
                    try processNumber()
                }
                number.append(".")
            case "-":
                if let last = number.last, "eE".contains(last) {
                    number.append(Character(char))
                } else {
                    try processNumber()
                    number = "-"
                }
            case "a" ... "z", "A" ... "Z":
                try processNumber()
                try processCommand()
                token = char
                isRelative = char > "Z"
            case " ", "\r", "\n", "\t", ",":
                try processNumber()
            default:
                throw SVGErrorType.unexpectedToken(String(char))
            }
        }
        try processNumber()
        try processCommand()
        self.commands = commands
    }
}

enum SVGErrorType: Error, Hashable {
    case unexpectedToken(String)
    case unexpectedArgument(for: String, expected: Int)
    case missingArgument(for: String, expected: Int)

    var message: String {
        switch self {
        case let .unexpectedToken(string):
            return "Unexpected token '\(string)'"
        case let .unexpectedArgument(command, _):
            return "Too many arguments for '\(command)'"
        case let .missingArgument(command, _):
            return "Missing argument for '\(command)'"
        }
    }
}

enum SVGCommand: Hashable {
    case moveTo(SVGPoint)
    case lineTo(SVGPoint)
    case cubic(SVGPoint, SVGPoint, SVGPoint)
    case quadratic(SVGPoint, SVGPoint)
    case arc(SVGArc)
    case end
}

extension SVGCommand {
    var point: SVGPoint {
        switch self {
        case let .moveTo(point),
             let .lineTo(point),
             let .cubic(_, _, point),
             let .quadratic(_, point):
            return point
        case let .arc(arc):
            return arc.end
        case .end:
            return .zero
        }
    }

    var control1: SVGPoint? {
        switch self {
        case let .cubic(control1, _, _), let .quadratic(control1, _):
            return control1
        case .moveTo, .lineTo, .arc, .end:
            return nil
        }
    }

    var control2: SVGPoint? {
        switch self {
        case let .cubic(_, control2, _):
            return control2
        case .moveTo, .lineTo, .quadratic, .arc, .end:
            return nil
        }
    }

    fileprivate func relative(to last: SVGCommand?) -> SVGCommand {
        guard let last = last?.point else {
            return self
        }
        switch self {
        case let .moveTo(point):
            return .moveTo(point + last)
        case let .lineTo(point):
            return .lineTo(point + last)
        case let .cubic(control1, control2, point):
            return .cubic(control1 + last, control2 + last, point + last)
        case let .quadratic(control, point):
            return .quadratic(control + last, point + last)
        case let .arc(arc):
            return .arc(arc.relative(to: last))
        case .end:
            return .end
        }
    }
}

struct SVGPoint: Hashable {
    var x, y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

extension SVGPoint {
    static let zero = SVGPoint(x: 0, y: 0)

    static func + (lhs: SVGPoint, rhs: SVGPoint) -> SVGPoint {
        SVGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: SVGPoint, rhs: SVGPoint) -> SVGPoint {
        SVGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}

struct SVGArc: Hashable {
    var radius: SVGPoint
    var rotation: Double
    var largeArc: Bool
    var sweep: Bool
    var end: SVGPoint
}

extension SVGArc {
    func asBezierPath(from currentPoint: SVGPoint) -> [SVGCommand] {
        let px = currentPoint.x, py = currentPoint.y
        var rx = abs(radius.x), ry = abs(radius.y)
        let xr = rotation
        let largeArcFlag = largeArc
        let sweepFlag = sweep
        let cx = end.x, cy = end.y
        let sinphi = sin(xr), cosphi = cos(xr)

        func vectorAngle(
            _ ux: Double, _ uy: Double,
            _ vx: Double, _ vy: Double
        ) -> Double {
            let sign = (ux * vy - uy * vx < 0) ? -1.0 : 1.0
            let umag = sqrt(ux * ux + uy * uy), vmag = sqrt(vx * vx + vy * vy)
            let dot = ux * vx + uy * vy
            return sign * acos(max(-1, min(1, dot / (umag * vmag))))
        }

        func toEllipse(_ x: Double, _ y: Double) -> SVGPoint {
            let x = x * rx, y = y * ry
            let xp = cosphi * x - sinphi * y, yp = sinphi * x + cosphi * y
            return SVGPoint(x: xp + centerx, y: yp + centery)
        }

        let dx = (px - cx) / 2, dy = (py - cy) / 2
        let pxp = cosphi * dx + sinphi * dy, pyp = -sinphi * dx + cosphi * dy
        if pxp == 0, pyp == 0 {
            return []
        }

        let lambda = pow(pxp, 2) / pow(rx, 2) + pow(pyp, 2) / pow(ry, 2)
        if lambda > 1 {
            rx *= sqrt(lambda)
            ry *= sqrt(lambda)
        }

        let rxsq = pow(rx, 2), rysq = pow(ry, 2)
        let pxpsq = pow(pxp, 2), pypsq = pow(pyp, 2)

        var radicant = max(0, rxsq * rysq - rxsq * pypsq - rysq * pxpsq)
        radicant /= (rxsq * pypsq) + (rysq * pxpsq)
        radicant = sqrt(radicant) * (largeArcFlag != sweepFlag ? -1 : 1)

        let centerxp = radicant * rx / ry * pyp
        let centeryp = radicant * -ry / rx * pxp

        let centerx = cosphi * centerxp - sinphi * centeryp + (px + cx) / 2
        let centery = sinphi * centerxp + cosphi * centeryp + (py + cy) / 2

        let vx1 = (pxp - centerxp) / rx, vy1 = (pyp - centeryp) / ry
        let vx2 = (-pxp - centerxp) / rx, vy2 = (-pyp - centeryp) / ry

        var a1 = vectorAngle(1, 0, vx1, vy1)
        var a2 = vectorAngle(vx1, vy1, vx2, vy2)
        if sweepFlag, a2 > 0 {
            a2 -= .pi * 2
        } else if !sweepFlag, a2 < 0 {
            a2 += .pi * 2
        }

        let segments = max(ceil(abs(a2) / (.pi / 2)), 1)
        a2 /= segments
        let a = 4 / 3 * tan(a2 / 4)
        return (0 ..< Int(segments)).map { _ in
            let x1 = cos(a1), y1 = sin(a1)
            let x2 = cos(a1 + a2), y2 = sin(a1 + a2)

            let p1 = toEllipse(x1 - y1 * a, y1 + x1 * a)
            let p2 = toEllipse(x2 + y2 * a, y2 - x2 * a)
            let p = toEllipse(x2, y2)

            a1 += a2
            return SVGCommand.cubic(p1, p2, p)
        }
    }

    fileprivate func relative(to last: SVGPoint) -> SVGArc {
        var arc = self
        arc.end = arc.end + last
        return arc
    }
}
