import Foundation

public struct Point: Codable, Equatable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct Vector: Codable, Equatable {
    public var dx: Double
    public var dy: Double

    public init(dx: Double, dy: Double) {
        self.dx = dx
        self.dy = dy
    }
}

public struct Size: Codable, Equatable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public struct AffineTransform: Codable, Equatable {
    public var a: Double
    public var b: Double
    public var c: Double
    public var d: Double
    public var tx: Double
    public var ty: Double

    public init(a: Double, b: Double, c: Double, d: Double, tx: Double, ty: Double) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.tx = tx
        self.ty = ty
    }
}

public struct EdgeInsets: Codable, Equatable {
    public var top: Double
    public var left: Double
    public var bottom: Double
    public var right: Double

    public init(top: Double, left: Double, bottom: Double, right: Double) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
}

public struct Offset: Codable, Equatable {
    public var horizontal: Double
    public var vertical: Double

    public init(horizontal: Double, vertical: Double) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
}

public struct ShadowValue: Codable, Equatable {
    public var offsetWidth: Double
    public var offsetHeight: Double
    public var opacity: Double
    public var radius: Double
    public var colorRGBA: [Double]?

    public init(
        offsetWidth: Double,
        offsetHeight: Double,
        opacity: Double,
        radius: Double,
        colorRGBA: [Double]? = nil
    ) {
        self.offsetWidth = offsetWidth
        self.offsetHeight = offsetHeight
        self.opacity = opacity
        self.radius = radius
        self.colorRGBA = colorRGBA
    }
}

public enum WireAttrValue: Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case numbers([Double])
    case strings([String])
    case stringGroups([[String]])
    case point(Point)
    case vector(Vector)
    case size(Size)
    case rect(Rect)
    case transform(AffineTransform)
    case insets(EdgeInsets)
    case offset(Offset)
    case shadow(ShadowValue)
    case json(String)
    case custom(String)
}

extension WireAttrValue: Codable {
    private enum CodingKeys: String, CodingKey { case kind, value }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .null:                try c.encode("null",         forKey: .kind)
        case .bool(let v):         try c.encode("bool",         forKey: .kind); try c.encode(v, forKey: .value)
        case .number(let v):       try c.encode("number",       forKey: .kind); try c.encode(v, forKey: .value)
        case .string(let v):       try c.encode("string",       forKey: .kind); try c.encode(v, forKey: .value)
        case .numbers(let v):      try c.encode("numbers",      forKey: .kind); try c.encode(v, forKey: .value)
        case .strings(let v):      try c.encode("strings",      forKey: .kind); try c.encode(v, forKey: .value)
        case .stringGroups(let v): try c.encode("stringGroups", forKey: .kind); try c.encode(v, forKey: .value)
        case .point(let v):        try c.encode("point",        forKey: .kind); try c.encode(v, forKey: .value)
        case .vector(let v):       try c.encode("vector",       forKey: .kind); try c.encode(v, forKey: .value)
        case .size(let v):         try c.encode("size",         forKey: .kind); try c.encode(v, forKey: .value)
        case .rect(let v):         try c.encode("rect",         forKey: .kind); try c.encode(v, forKey: .value)
        case .transform(let v):    try c.encode("transform",    forKey: .kind); try c.encode(v, forKey: .value)
        case .insets(let v):       try c.encode("insets",       forKey: .kind); try c.encode(v, forKey: .value)
        case .offset(let v):       try c.encode("offset",       forKey: .kind); try c.encode(v, forKey: .value)
        case .shadow(let v):       try c.encode("shadow",       forKey: .kind); try c.encode(v, forKey: .value)
        case .json(let v):         try c.encode("json",         forKey: .kind); try c.encode(v, forKey: .value)
        case .custom(let v):       try c.encode("custom",       forKey: .kind); try c.encode(v, forKey: .value)
        }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(String.self, forKey: .kind) {
        case "null":         self = .null
        case "bool":         self = .bool(try c.decode(Bool.self,               forKey: .value))
        case "number":       self = .number(try c.decode(Double.self,           forKey: .value))
        case "string":       self = .string(try c.decode(String.self,           forKey: .value))
        case "numbers":      self = .numbers(try c.decode([Double].self,        forKey: .value))
        case "strings":      self = .strings(try c.decode([String].self,        forKey: .value))
        case "stringGroups": self = .stringGroups(try c.decode([[String]].self, forKey: .value))
        case "point":        self = .point(try c.decode(Point.self,             forKey: .value))
        case "vector":       self = .vector(try c.decode(Vector.self,           forKey: .value))
        case "size":         self = .size(try c.decode(Size.self,               forKey: .value))
        case "rect":         self = .rect(try c.decode(Rect.self,               forKey: .value))
        case "transform":    self = .transform(try c.decode(AffineTransform.self, forKey: .value))
        case "insets":       self = .insets(try c.decode(EdgeInsets.self,       forKey: .value))
        case "offset":       self = .offset(try c.decode(Offset.self,           forKey: .value))
        case "shadow":       self = .shadow(try c.decode(ShadowValue.self,      forKey: .value))
        case "json":         self = .json(try c.decode(String.self,             forKey: .value))
        case "custom":       self = .custom(try c.decode(String.self,           forKey: .value))
        default:             self = .null
        }
    }
}

public struct WireAttribute: Codable, Equatable {
    public var identifier: String?
    public var displayTitle: String?
    public var attrType: Int
    public var value: WireAttrValue?
    public var extraValue: WireAttrValue?
    public var customSetterID: String?

    public init(
        identifier: String? = nil,
        displayTitle: String? = nil,
        attrType: Int,
        value: WireAttrValue? = nil,
        extraValue: WireAttrValue? = nil,
        customSetterID: String? = nil
    ) {
        self.identifier = identifier
        self.displayTitle = displayTitle
        self.attrType = attrType
        self.value = value
        self.extraValue = extraValue
        self.customSetterID = customSetterID
    }
}

public struct WireAttributesSection: Codable, Equatable {
    public var identifier: String?
    public var attributes: [WireAttribute]?

    public init(identifier: String? = nil, attributes: [WireAttribute]? = nil) {
        self.identifier = identifier
        self.attributes = attributes
    }
}

public struct WireAttributesGroup: Codable, Equatable {
    public var identifier: String?
    public var userCustomTitle: String?
    public var attrSections: [WireAttributesSection]?

    public init(
        identifier: String? = nil,
        userCustomTitle: String? = nil,
        attrSections: [WireAttributesSection]? = nil
    ) {
        self.identifier = identifier
        self.userCustomTitle = userCustomTitle
        self.attrSections = attrSections
    }
}

public struct WireStaticAsyncUpdateTask: Codable, Equatable {
    public var oid: UInt
    public var taskType: Int
    public var attrRequest: Int
    public var needBasisVisualInfo: Bool
    public var needSubitems: Bool
    public var clientReadableVersion: String?

    public init(
        oid: UInt,
        taskType: Int,
        attrRequest: Int = 0,
        needBasisVisualInfo: Bool = false,
        needSubitems: Bool = false,
        clientReadableVersion: String? = nil
    ) {
        self.oid = oid
        self.taskType = taskType
        self.attrRequest = attrRequest
        self.needBasisVisualInfo = needBasisVisualInfo
        self.needSubitems = needSubitems
        self.clientReadableVersion = clientReadableVersion
    }
}

public struct WireStaticAsyncUpdateTasksPackage: Codable, Equatable {
    public var tasks: [WireStaticAsyncUpdateTask]?

    public init(tasks: [WireStaticAsyncUpdateTask]? = nil) {
        self.tasks = tasks
    }
}
