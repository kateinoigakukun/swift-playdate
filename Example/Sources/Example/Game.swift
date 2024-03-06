@_exported import _CPlaydate
#if os(macOS)
import Darwin
#endif

struct Context {
    let playdate: UnsafeMutablePointer<PlaydateAPI>
}

typealias Vector = SIMD2<Float32>

extension Vector {
    func collisioned(normal: Vector) -> Vector {
        self - (2.0 * self.innerProduct(normal)) * normal
    }
    func innerProduct(_ other: Vector) -> Float32 {
        self.x * other.x + self.y * other.y
    }
    
    init(radius: Float32, theta: Float32) {
        self = .init(radius * cosf(theta), radius * sinf(theta))
    }
}

struct Game {
    let bird: Sprite
    var velocity: Vector
    
    init() {
        let image = Image(path: "the-bird.png")
        let bird = Sprite(image: image)
        bird.collideRect = .init(x: 0.0, y: 0.0, width: 85.0, height: 85.0)
        bird.add()
        
        self.velocity = .init(radius: 5.0, theta: -.pi * 0.4)

        self.bird = bird
        self.bird.move(toX: Float(LCD_COLUMNS / 2), y: Float(3 * LCD_ROWS / 4))
        self.bird.setCollisionResponseFunction { _, _ in
            return kCollisionTypeBounce
        }
        self.bird.setUpdateFunction { handle in
            let bird = Sprite(borrowing: handle!)
            let bounds = bird.position
            let newX = game.velocity.x + bounds.x
            let newY = game.velocity.y + bounds.y
            var conflicts = 0
            bird.moveWithCollisions(goalX: newX, y: newY).forEach { collision in
                let normal = Vector(
                    Float32(collision.normal.x),
                    Float32(collision.normal.y)
                )
                conflicts += 1
                game.velocity = game.velocity.collisioned(normal: normal)
            }
        }

        self.setupWalls()
        Sprite.draw()
    }

    func setupWalls() {
        let bar: Float = 10.0
        let walls: [PDRect] = [
            .init(x: 0.0, y: 0.0, width: Float(LCD_COLUMNS), height: bar),
            .init(x: 0.0, y: 0.0, width: bar, height: Float(LCD_ROWS)),
            .init(x: (Float(LCD_COLUMNS) - bar) / 2.0, y: 0.0, width: bar, height: Float(LCD_ROWS)),
            .init(x: 0.0, y: (Float(LCD_ROWS) - bar) / 2.0, width: Float(LCD_COLUMNS), height: bar),
        ]
        
        for wall in walls {
            let sprite = Sprite()
            let bounds = PDRect(x: wall.x, y: wall.y, width: wall.width, height: wall.height)
            sprite.bounds = bounds
            sprite.collideRect = bounds
            sprite.setCollisionResponseFunction { _, _ in kCollisionTypeBounce }
            sprite.add()
        }
    }
}
var game: Game!

@_cdecl("update")
func update(playdate: UnsafeMutableRawPointer!) -> Int32 {
    Sprite.updateAndDrawSprites()
    return 1
}

@_cdecl("eventHandler")
public func eventHandler(
    playdate: UnsafeMutablePointer<PlaydateAPI>,
    event: PDSystemEvent,
    arg: UInt32
) -> Int32 {
    switch event {
    case kEventInit:
        playdateAPI = playdate
        game = Game()
        playdate.pointee.system.pointee.setUpdateCallback(update, playdate)
    default:
        break
    }
    return 0
}

var playdateAPI: UnsafeMutablePointer<PlaydateAPI>!

struct Image {
    let handle: OpaquePointer
    
    init(path: StaticString) {
        self.handle = path.withUTF8Buffer {
            playdateAPI.pointee.graphics.pointee.loadBitmap($0.baseAddress, nil)!
        }
    }
}

struct Sprite {
    let handle: OpaquePointer
    var bounds: PDRect {
        get {
            playdateAPI.pointee.sprite.pointee.getBounds(self.handle)
        }
        nonmutating set {
            playdateAPI.pointee.sprite.pointee.setBounds(self.handle, newValue)
        }
    }

    var position: (x: Float, y: Float) {
        var x: Float = 0.0, y: Float = 0.0
        playdateAPI.pointee.sprite.pointee.getPosition(self.handle, &x, &y)
        return (x, y)
    }
    
    var collideRect: PDRect {
        get {
            playdateAPI.pointee.sprite.pointee.getCollideRect(self.handle)
        }
        nonmutating set {
            playdateAPI.pointee.sprite.pointee.setCollideRect(self.handle, newValue)
        }
    }
    
    init() {
        self.handle = playdateAPI.pointee.sprite.pointee.newSprite()!
    }
    
    init(borrowing handle: OpaquePointer) {
        self.handle = handle
    }
    
    init(image: borrowing Image) {
        self.init()
        self.setImage(image)
    }
    
    func setImage(_ image: borrowing Image, flip: LCDBitmapFlip = kBitmapUnflipped) {
        playdateAPI.pointee.sprite.pointee.setImage(self.handle, image.handle, flip)
    }
    
    func move(toX x: Float, y: Float) {
        playdateAPI.pointee.sprite.pointee.moveTo(self.handle, x, y)
    }
    
    func add() {
        playdateAPI.pointee.sprite.pointee.addSprite(self.handle)
    }
    
    func setCollisionResponseFunction(
        _ body: @escaping @convention(c) (_ self: OpaquePointer?, _ other: OpaquePointer?) -> SpriteCollisionResponseType
    ) {
        playdateAPI.pointee.sprite.pointee.setCollisionResponseFunction(self.handle, body)
    }
    
    func setUpdateFunction(
        _ body: @convention(c) (OpaquePointer?) -> Void
    ) {
        playdateAPI.pointee.sprite.pointee.setUpdateFunction(self.handle, body)
    }
    
    struct Collisions: ~Copyable {
        let buffer: UnsafeBufferPointer<SpriteCollisionInfo>
        deinit { buffer.deallocate() }
        
        consuming func forEach(_ body: (SpriteCollisionInfo) -> Void) {
            buffer.forEach(body)
        }
    }
    
    func moveWithCollisions(
        goalX x: Float, y: Float
    ) -> Collisions {
        var actualX: Float = 0.0
        var actualY: Float = 0.0
        var collisionCount: Int32 = 0
        let collisionBase = playdateAPI.pointee.sprite.pointee.moveWithCollisions(
            self.handle, x, y, &actualX, &actualY, &collisionCount
        )
        return Collisions(buffer: UnsafeBufferPointer(start: collisionBase, count: Int(collisionCount)))
    }
    
    static func updateAndDrawSprites() {
        playdateAPI.pointee.sprite.pointee.updateAndDrawSprites()
    }

    static func draw() {
        playdateAPI.pointee.sprite.pointee.drawSprites()
    }
}

enum Display {
    static func setRefreshRate(_ rate: Float) {
        playdateAPI.pointee.display.pointee.setRefreshRate(rate)
    }
}
