"use strict";(self.webpackChunkdocs_site=self.webpackChunkdocs_site||[]).push([["452"],{2029(e,s,a){a.r(s),a.d(s,{default:()=>f});var i=a(4848),t=a(4164),l=a(5310),n=a(898),c=a(1085),r=a(2072);let o={features:"features_t9lD"},d=[{id:"01",title:"Stateful Scene Graph",description:(0,i.jsxs)(i.Fragment,{children:["Build your game tree using standard Flutter widgets and ",(0,i.jsx)("code",{children:"sync*"})," generators. Manage complex entity lifecycles with the familiar ",(0,i.jsx)("code",{children:"StatefulGameWidget"})," pattern."]})},{id:"02",title:"Entity-Component-System (ECS)",description:(0,i.jsx)(i.Fragment,{children:"A flexible Entity Component System. Decouple your game logic into reusable components that can be attached and queried at runtime with ease."})},{id:"03",title:"Action-Based Input",description:(0,i.jsx)(i.Fragment,{children:"Decouple game logic from physical hardware. Bind multiple keys or touch controls to logical actions, with built-in support for composite vectors and deadzones."})}];function h({id:e,title:s,description:a}){return(0,i.jsx)("div",{className:(0,t.A)("col col--4"),children:(0,i.jsxs)("div",{className:o.featureCard,children:[(0,i.jsx)("span",{className:o.featureId,children:e}),(0,i.jsx)(r.A,{as:"h3",children:s}),(0,i.jsx)("p",{children:a})]})})}function m(){return(0,i.jsx)("section",{className:o.features,children:(0,i.jsx)("div",{className:"container",children:(0,i.jsx)("div",{className:"row",children:d.map((e,s)=>(0,i.jsx)(h,{...e},s))})})})}var x=a(1113);let u="featureHighlight_cFdU",p="highlightTitle_XiMt",g="highlightDescription_TEDe",j="colLeft_rdDF",N="colRight_TN0y",v="dot_K917";function y(){let{siteConfig:e}=(0,n.A)();return(0,i.jsxs)("header",{className:(0,t.A)("hero","heroBanner_qdFl"),children:[(0,i.jsxs)("div",{className:"container",children:[(0,i.jsx)(r.A,{as:"h1",className:"heroTitle_qg2I",children:e.title}),(0,i.jsx)("p",{className:"heroSubtitle_jFu1",children:e.tagline}),(0,i.jsxs)("div",{className:"buttons_AeoN",children:[(0,i.jsx)(l.A,{className:"button button--secondary button--lg",to:"/docs/core-concepts",children:"Get Started"}),(0,i.jsx)(l.A,{className:"button button--outline button--lg",to:"https://github.com/sunarya-thito/goo2d",children:"GitHub"})]})]}),(0,i.jsxs)("div",{className:"scrollIndicator_PUuy",children:[(0,i.jsx)("span",{className:"scrollText_Ze4G",children:"Scroll to explore"}),(0,i.jsx)("div",{className:"scrollLine_dBGP"})]})]})}function A({children:e}){return(0,i.jsxs)("div",{className:"codeWindow__yDo",children:[(0,i.jsxs)("div",{className:"windowHeader_PUi8",children:[(0,i.jsx)("div",{className:(0,t.A)(v,"dotRed_jHVn")}),(0,i.jsx)("div",{className:(0,t.A)(v,"dotYellow_dCsn")}),(0,i.jsx)("div",{className:(0,t.A)(v,"dotGreen_o65z")})]}),(0,i.jsx)("div",{className:"windowContent_lkH5",children:e})]})}function f(){let{siteConfig:e}=(0,n.A)();return(0,i.jsx)(c.A,{title:`${e.title} | ${e.tagline}`,description:"A low level Flutter 2D game engine",children:(0,i.jsxs)("div",{className:"pageContainer_o1Jp",children:[(0,i.jsx)(y,{}),(0,i.jsxs)("main",{children:[(0,i.jsx)(m,{}),(0,i.jsx)("section",{className:u,children:(0,i.jsx)("div",{className:"container",children:(0,i.jsxs)("div",{className:"row",style:{alignItems:"center"},children:[(0,i.jsxs)("div",{className:(0,t.A)("col col--5",j),children:[(0,i.jsx)(r.A,{as:"h2",className:p,children:"Stateful Scene Graph"}),(0,i.jsxs)("p",{className:g,children:["Build complex game worlds by stacking ",(0,i.jsx)("b",{children:"GameWidgets"}),". Goo2D leverages standard Flutter ",(0,i.jsx)("code",{children:"build"})," methods and ",(0,i.jsx)("code",{children:"sync*"})," generators to manage hierarchical entity trees."]})]}),(0,i.jsx)("div",{className:(0,t.A)("col col--7",N),children:(0,i.jsx)(A,{children:(0,i.jsx)(x.A,{language:"dart",children:`@override
Iterable<Widget> build(BuildContext context) sync* {
  yield GameWidget(
    key: const GameTag('Player'),
    components: () => [
      ObjectTransform(),
      SpriteRenderer()..sprite = playerSprite,
      PlayerController(),
    ],
  );
}`})})})]})})}),(0,i.jsx)("section",{className:u,children:(0,i.jsx)("div",{className:"container",children:(0,i.jsxs)("div",{className:"row",style:{alignItems:"center"},children:[(0,i.jsx)("div",{className:(0,t.A)("col col--7",j),children:(0,i.jsx)(A,{children:(0,i.jsx)(x.A,{language:"dart",children:`class Player extends Behavior {
  @override
  void update() {
    // Decouple logic from representation
    final trans = getComponent<ObjectTransform>();
    final input = getComponent<PlayerInput>();
    
    trans.position += input.dir * 5.0 * game.ticker.deltaTime;
  }
}`})})}),(0,i.jsxs)("div",{className:(0,t.A)("col col--5",N),children:[(0,i.jsx)(r.A,{as:"h2",className:p,children:"ECS"}),(0,i.jsx)("p",{className:g,children:"A flexible Entity Component System. Decouple your game logic into reusable components that can be attached and queried at runtime with ease."})]})]})})}),(0,i.jsx)("section",{className:u,children:(0,i.jsx)("div",{className:"container",children:(0,i.jsxs)("div",{className:"row",style:{alignItems:"center"},children:[(0,i.jsxs)("div",{className:(0,t.A)("col col--5",j),children:[(0,i.jsx)(r.A,{as:"h2",className:p,children:"Asset Management"}),(0,i.jsx)("p",{className:g,children:"Type-safe asset management with Enums. Built-in caching and reactive loading progress out of the box, ensuring your game assets are always organized."})]}),(0,i.jsx)("div",{className:(0,t.A)("col col--7",N),children:(0,i.jsx)(A,{children:(0,i.jsx)(x.A,{language:"dart",children:`enum MySprites with AssetEnum, TextureAssetEnum {
  ship, boss, explosion;
  @override
  AssetSource get source => 
    AssetSource.local("assets/sprites/$name.png");
}

// Reactive loading with streams
await for (final p in GameAsset.loadAll(MySprites.values)) {
  updateProgress(p.assetLoaded / p.assetCount);
}`})})})]})})}),(0,i.jsx)("section",{className:u,children:(0,i.jsx)("div",{className:"container",children:(0,i.jsxs)("div",{className:"row",style:{alignItems:"center"},children:[(0,i.jsx)("div",{className:(0,t.A)("col col--7",j),children:(0,i.jsx)(A,{children:(0,i.jsx)(x.A,{language:"dart",children:`final sheet = SpriteSheet.grid(
  texture: MySprites.explosion,
  columns: 8, rows: 8,
  ppu: 64.0,
);

// Instant frame access via coordinates
renderer.sprite = sheet[(0, 4)];`})})}),(0,i.jsxs)("div",{className:(0,t.A)("col col--5",N),children:[(0,i.jsx)(r.A,{as:"h2",className:p,children:"Sprite Sheets"}),(0,i.jsx)("p",{className:g,children:"Efficiently handle complex atlases and grids. Support for PPU (Pixels Per Unit) scaling and flexible pivot points for accurate rendering."})]})]})})}),(0,i.jsx)("section",{className:u,children:(0,i.jsx)("div",{className:"container",children:(0,i.jsxs)("div",{className:"row",style:{alignItems:"center"},children:[(0,i.jsxs)("div",{className:(0,t.A)("col col--5",j),children:[(0,i.jsx)(r.A,{as:"h2",className:p,children:"Collisions"}),(0,i.jsx)("p",{className:g,children:"Manage physical interactions without the widget tree overhead. Robust callbacks for hits, triggers, and screen-boundary events."})]}),(0,i.jsx)("div",{className:(0,t.A)("col col--7",N),children:(0,i.jsx)(A,{children:(0,i.jsx)(x.A,{language:"dart",children:`class Enemy extends Behavior with Collidable {
  @override
  void onCollision(CollisionEvent event) {
    // Precise filtering with GameTags
    if (event.other.gameObject.tag == const GameTag('Player')) {
      print("Hit player!");
      gameObject.destroy();
    }
  }
}`})})})]})})}),(0,i.jsx)("section",{className:u,children:(0,i.jsx)("div",{className:"container",children:(0,i.jsxs)("div",{className:"row",style:{alignItems:"center"},children:[(0,i.jsx)("div",{className:(0,t.A)("col col--7",j),children:(0,i.jsx)(A,{children:(0,i.jsx)(x.A,{language:"dart",children:`moveAction = createInputAction(
  name: 'move',
  type: InputActionType.value,
  bindings: [
    InputBinding.composite(
      up: game.input.keyboard.keyW,
      down: game.input.keyboard.keyS,
      left: game.input.keyboard.keyA,
      right: game.input.keyboard.keyD,
    ),
  ],
);

// Read 2D vector anywhere
final dir = moveAction.readValue<Offset>();`})})}),(0,i.jsxs)("div",{className:(0,t.A)("col col--5",N),children:[(0,i.jsx)(r.A,{as:"h2",className:p,children:"Input System"}),(0,i.jsx)("p",{className:g,children:"Modern, action-based input system. Bind multiple physical controls to a single logical action for cross-platform support."})]})]})})}),(0,i.jsx)("section",{className:"gameDemo_M366",children:(0,i.jsx)("div",{className:"demoWrapper_oxt0",children:(0,i.jsx)("iframe",{src:"/goo2d/play/#/",width:"100%",height:"100%",style:{border:"none",background:"#000"},title:"Goo2D Demo"})})})]})]})})}}}]);