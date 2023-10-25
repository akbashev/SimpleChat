import DistributedCluster
import HummingbirdWSCore
import HummingbirdWebSocket
import HummingbirdFoundation
import Backend
import VirtualActor

enum StandaloneNode: Node {
  static func run(
    host: String,
    port: Int
  ) async throws {
    let actorSystem = await ClusterSystem("frontend") {
      $0.bindHost = host
      $0.bindPort = port
    }
    let roomNode = await ClusterSystem("room") {
      $0.bindHost = host
      $0.bindPort = port + 1
    }
    let dbNode = await ClusterSystem("database") {
      $0.bindHost = host
      $0.bindPort = port + 2
    }
    
    roomNode.cluster.join(node: actorSystem.cluster.node)
    dbNode.cluster.join(node: actorSystem.cluster.node)
    try await Self.ensureCluster(actorSystem, roomNode, dbNode, within: .seconds(10))
    
    let app = HBApplication(
      configuration: .init(
        address: .hostname(
          host,
          port: 8080
        ),
        serverName: "frontend"
      )
    )

    app.encoder = JSONEncoder()
    app.decoder = JSONDecoder()
    
    // We need references for ARC not to clean them up
    let frontend = try await FrontendNode(
      actorSystem: actorSystem,
      app: app
    )
    let room = await VirtualNode<Room, RoomInfo>(
      actorSystem: roomNode
    )
    let databaseNode = try await DatabaseNode(
      actorSystem: dbNode
    )
    frontend
      .configure(
        router: app.router
      )
    
    try await actorSystem.terminated
  }
}
