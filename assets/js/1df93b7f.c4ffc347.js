"use strict";(self.webpackChunkdocs_site=self.webpackChunkdocs_site||[]).push([["452"],{2029(e,s,t){t.r(s),t.d(s,{default:()=>C});var a=t(4848),i=t(6540),n=t(4164),r=t(5310),o=t(898),l=t(1085),c=t(2072);let d={features:"features_t9lD"},p=[{id:"01",title:"Stateful Scene Graph",description:(0,a.jsxs)(a.Fragment,{children:["Build your game tree using standard Flutter widgets and ",(0,a.jsx)("code",{children:"sync*"})," generators. Manage complex entity lifecycles with the familiar ",(0,a.jsx)("code",{children:"StatefulGameWidget"})," pattern."]})},{id:"02",title:"Entity-Component-System (ECS)",description:(0,a.jsx)(a.Fragment,{children:"A flexible Entity Component System. Decouple your game logic into reusable components that can be attached and queried at runtime with ease."})},{id:"03",title:"Action-Based Input",description:(0,a.jsx)(a.Fragment,{children:"Decouple game logic from physical hardware. Bind multiple keys or touch controls to logical actions, with built-in support for composite vectors and deadzones."})}];function h({id:e,title:s,description:t}){return(0,a.jsx)("div",{className:(0,n.A)("col col--4"),children:(0,a.jsxs)("div",{className:d.featureCard,children:[(0,a.jsx)("span",{className:d.featureId,children:e}),(0,a.jsx)(c.A,{as:"h3",children:s}),(0,a.jsx)("p",{children:t})]})})}function m(){return(0,a.jsx)("section",{className:d.features,children:(0,a.jsx)("div",{className:"container",children:(0,a.jsx)("div",{className:"row",children:p.map((e,s)=>(0,a.jsx)(h,{...e},s))})})})}var x=t(1113);let u="floatingShape_Gn0E",g="wireframeBox_vJoF",y="featureHighlight_cFdU",f="highlightTitle_XiMt",j="highlightDescription_TEDe",v="colLeft_rdDF",b="colRight_TN0y",N="dot_K917",A="triggerActive_iYf8",_="triggerActiveLabel_DZMy";function w(){let{siteConfig:e}=(0,o.A)(),[s,t]=(0,i.useState)({x:70,y:30}),[l,d]=(0,i.useState)({zone04:!1,zone12:!1,zone07:!1}),[p,h]=(0,i.useState)(0),m=(0,i.useRef)(null),x=(0,i.useRef)(null),y=(0,i.useRef)(null),f=(0,i.useRef)(null),j=(e,s)=>!(e.right<s.left||e.left>s.right||e.bottom<s.top||e.top>s.bottom);(0,i.useEffect)(()=>{let e,s=performance.now(),a=i=>{let n=(i-s)/1e3,r=50+35*Math.cos(.4*n)+5*Math.sin(.1*n),o=45+30*Math.sin(.5*n)+5*Math.cos(.1*n),l=-.4*Math.sin(.4*n)*35+.1*Math.cos(.1*n)*5,c=180/Math.PI*Math.atan2(.5*Math.cos(.5*n)*30-.1*Math.sin(.1*n)*5,l)+90;if(h(e=>{let s=c-e;for(;s<-180;)s+=360;for(;s>180;)s-=360;return e+.1*s}),t({x:r,y:o}),m.current){let e=m.current.getBoundingClientRect();d({zone04:!!x.current&&j(e,x.current.getBoundingClientRect()),zone12:!!y.current&&j(e,y.current.getBoundingClientRect()),zone07:!!f.current&&j(e,f.current.getBoundingClientRect())})}e=requestAnimationFrame(a)};return e=requestAnimationFrame(a),()=>cancelAnimationFrame(e)},[]);let v=`
class BouncingBehavior extends Behavior with Tickable, Collidable {
  Offset _velocity = const Offset(2.0, 1.5);
  late SpriteRenderer _renderer;

  @override
  void onMounted() {
    _renderer = SpriteRenderer()..sprite = GameSprite(texture: Asset.enemy);
    addComponent(_renderer);
  }

  @override
  void onUpdate(double dt) {
    final transform = getComponent<ObjectTransform>();
    transform.position += _velocity * dt;
  }
}

class MyGameWorld extends GameState {
  @override
  Iterable<Widget> build(BuildContext context) sync* {
    yield GameWidget(
      components: () => [
        ObjectTransform(),
        Camera()..orthographicSize = 5.0,
        BouncingBehavior(),
      ],
    );
  }
}

void main() => runApp(const Game(child: MyGameWorld()));

// Internal Pipeline Logic
void _flushBatch() {
  final buffer = _gl.createBuffer();
  _gl.bindBuffer(GL.ARRAY_BUFFER, buffer);
  _gl.bufferData(GL.ARRAY_BUFFER, _vertexData, GL.DYNAMIC_DRAW);
}
  `.repeat(4).split("\n").map((e,s)=>(e+" ".repeat(20)).repeat(4).substring(s%12)).join("\n"),b=Object.values(l).some(e=>e);return(0,a.jsxs)("header",{className:(0,n.A)("hero","heroBanner_qdFl"),children:[(0,a.jsx)("div",{className:"noise_kMLX"}),(0,a.jsx)("div",{className:"scanlines_h7XZ"}),(0,a.jsx)("div",{className:"codeBackground_ykOZ",children:v}),(0,a.jsxs)("div",{className:"perfGraph_W7Me",children:[(0,a.jsx)("div",{style:{fontSize:"10px",color:"var(--brand-primary)",marginBottom:"8px",fontFamily:"monospace",letterSpacing:"0.1em"},children:"FRAME_TIME (ms) [ACTIVE]"}),(0,a.jsx)("div",{style:{display:"flex",alignItems:"flex-end",height:"80px",gap:"4px",borderLeft:"1px solid var(--brand-primary)",borderBottom:"1px solid var(--brand-primary)",padding:"4px"},children:[...Array(30)].map((e,s)=>(0,a.jsx)("div",{className:"perfBar_Doru",style:{flex:1,height:`${[16,17,16,18,16,16,32,16,17,16,16,19,16,16,16,24,16,16,16,17,16,16,16,16,16,18,16,16,20,16][s]}px`,backgroundColor:6===s||15===s||28===s?"#13b9fd":"var(--brand-primary)",opacity:.7,animationDelay:`${.05*s%.3}s`,animationDuration:`${.1+s%3*.05}s`,transformOrigin:"bottom"}},s))}),(0,a.jsxs)("div",{style:{display:"flex",justifyContent:"space-between",marginTop:"4px",fontSize:"8px",color:"var(--brand-primary)",fontFamily:"monospace"},children:[(0,a.jsx)("span",{children:"0ms"}),(0,a.jsx)("span",{children:"16.6ms (60fps)"})]})]}),(0,a.jsxs)("div",{ref:m,style:{position:"absolute",left:`${s.x}%`,top:`${s.y}%`,width:"80px",height:"80px",zIndex:1,pointerEvents:"none",opacity:.8,transform:"translate(-50%, -50%)"},children:[(0,a.jsx)("div",{style:{width:"100%",height:"100%",transform:`rotate(${p}deg)`,transition:"transform 0.1s linear"},children:(0,a.jsxs)("svg",{width:"100%",height:"100%",viewBox:"0 0 100 100",style:{filter:"drop-shadow(0 0 10px rgba(1, 117, 194, 0.4))"},children:[(0,a.jsx)("path",{d:"M50 10 L85 85 L50 70 L15 85 Z",fill:"rgba(255, 255, 255, 0.9)",stroke:"var(--brand-primary)",strokeWidth:"3"}),(0,a.jsx)("path",{d:"M50 25 L65 60 L50 50 L35 60 Z",fill:"var(--brand-primary)",opacity:"0.6"}),(0,a.jsx)("rect",{x:"42",y:"75",width:"16",height:"10",fill:"var(--brand-primary)",opacity:"0.4",children:(0,a.jsx)("animate",{attributeName:"opacity",values:"0.4;1;0.4",dur:"0.2s",repeatCount:"indefinite"})})]})}),(0,a.jsx)("div",{style:{position:"absolute",inset:"-10px",border:"1px dashed var(--brand-primary)",backgroundColor:b?"rgba(1, 117, 194, 0.2)":"transparent",borderRadius:"50%",opacity:.8,aspectRatio:"1/1"},children:(0,a.jsxs)("span",{style:{position:"absolute",bottom:"-20px",left:"50%",transform:"translateX(-50%)",color:"var(--brand-primary)",fontSize:"9px",fontFamily:"monospace",whiteSpace:"nowrap",fontWeight:"bold"},children:["\u25CF ",b?"COLLISION_DETECTED":"CIRCLE_COLLIDER"]})})]}),(0,a.jsxs)("div",{ref:x,className:(0,n.A)(l.zone04&&A),style:{position:"absolute",bottom:"15%",right:"10%",width:"160px",height:"160px",border:"1px dashed rgba(1, 117, 194, 0.4)",backgroundColor:"rgba(1, 117, 194, 0.02)",zIndex:1,pointerEvents:"none",opacity:.8},children:[(0,a.jsx)("div",{className:(0,n.A)(l.zone04&&_),style:{position:"absolute",top:"0",left:"0",padding:"2px 6px",background:"rgba(1, 117, 194, 0.3)",color:"white",fontSize:"9px",fontFamily:"monospace"},children:"TRIGGER_ZONE_#04"}),(0,a.jsx)("div",{style:{position:"absolute",bottom:"6px",right:"6px",color:"var(--brand-primary)",fontSize:"10px",fontFamily:"monospace",opacity:.6},children:"OnOverlap: notify()"})]}),(0,a.jsx)("div",{ref:y,className:(0,n.A)(l.zone12&&A),style:{position:"absolute",top:"20%",left:"30%",width:"100px",height:"100px",border:"1px dashed rgba(1, 117, 194, 0.3)",zIndex:1,pointerEvents:"none",opacity:.5},children:(0,a.jsx)("div",{className:(0,n.A)(l.zone12&&_),style:{position:"absolute",top:"0",left:"0",padding:"1px 4px",background:"rgba(1, 117, 194, 0.2)",color:"white",fontSize:"8px",fontFamily:"monospace"},children:"EVENT_TRGR_#12"})}),(0,a.jsx)("div",{ref:f,className:(0,n.A)(l.zone07&&A),style:{position:"absolute",top:"60%",left:"15%",width:"120px",height:"120px",border:"1px dashed rgba(1, 117, 194, 0.3)",zIndex:1,pointerEvents:"none",opacity:.5},children:(0,a.jsx)("div",{className:(0,n.A)(l.zone07&&_),style:{position:"absolute",top:"0",left:"0",padding:"1px 4px",background:"rgba(1, 117, 194, 0.2)",color:"white",fontSize:"8px",fontFamily:"monospace"},children:"AREA_TRGR_#07"})}),(0,a.jsxs)("div",{style:{position:"absolute",top:"15%",right:"5%",display:"grid",gridTemplateColumns:"repeat(4, 30px)",gap:"6px",opacity:.6,zIndex:2},children:[[...Array(16)].map((e,s)=>(0,a.jsx)("div",{style:{width:"30px",height:"30px",border:"1px solid var(--brand-primary)",background:s%5==0?"rgba(1, 117, 194, 0.4)":"transparent"}},s)),(0,a.jsx)("div",{style:{gridColumn:"span 4",fontSize:"10px",color:"var(--brand-primary)",marginTop:"8px",fontFamily:"monospace",fontWeight:"bold"},children:"TEXTURE_ATLAS_01"})]}),(0,a.jsxs)("div",{className:"viewportInfo_D2I4",children:[(0,a.jsx)("div",{children:"FPS: 60.0"}),(0,a.jsx)("div",{children:"Delta: 16.6ms"}),(0,a.jsx)("div",{children:"VRAM: 124MB"}),(0,a.jsx)("div",{children:"Draws: 12"})]}),(0,a.jsx)("div",{className:"viewportCoords_LZBA",children:"viewport: 0,0,1920,1080"}),(0,a.jsxs)("div",{className:u,style:{width:"220px",height:"220px",left:"2%",top:"10%",animationDelay:"0s",opacity:.5},children:[(0,a.jsx)("div",{className:g}),(0,a.jsx)("span",{style:{position:"absolute",top:"-30px",left:"0",fontSize:"12px",color:"var(--brand-primary)",fontFamily:"monospace",fontWeight:"bold"},children:"VertexData_Buffer"})]}),(0,a.jsxs)("div",{className:u,style:{width:"160px",height:"160px",left:"88%",top:"20%",animationDelay:"-5s",opacity:.4},children:[(0,a.jsx)("div",{className:g}),(0,a.jsx)("span",{style:{position:"absolute",top:"-30px",left:"0",fontSize:"12px",color:"var(--brand-primary)",fontFamily:"monospace",fontWeight:"bold"},children:"SpriteBatcher_01"})]}),(0,a.jsxs)("div",{className:u,style:{width:"190px",height:"190px",left:"5%",top:"75%",animationDelay:"-12s",opacity:.4},children:[(0,a.jsx)("div",{className:g}),(0,a.jsx)("span",{style:{position:"absolute",top:"-30px",left:"0",fontSize:"12px",color:"var(--brand-primary)",fontFamily:"monospace",fontWeight:"bold"},children:"Texture_Slot#02"})]}),(0,a.jsxs)("div",{className:u,style:{width:"130px",height:"130px",left:"80%",top:"65%",animationDelay:"-8s",opacity:.1},children:[(0,a.jsx)("div",{className:g}),(0,a.jsx)("span",{style:{position:"absolute",top:"-25px",left:"0",fontSize:"10px",color:"var(--brand-primary)",fontFamily:"monospace"},children:"GPU_Resource_HNDL"})]}),(0,a.jsxs)("div",{className:u,style:{width:"100px",height:"100px",left:"40%",top:"5%",animationDelay:"-15s",opacity:.1},children:[(0,a.jsx)("div",{className:g}),(0,a.jsx)("span",{style:{position:"absolute",top:"-25px",left:"0",fontSize:"10px",color:"var(--brand-primary)",fontFamily:"monospace"},children:"Shader_Program_Cache"})]}),(0,a.jsxs)("div",{className:u,style:{width:"140px",height:"140px",left:"15%",top:"40%",animationDelay:"-2s",opacity:.08},children:[(0,a.jsx)("div",{className:g}),(0,a.jsx)("span",{style:{position:"absolute",top:"-25px",left:"0",fontSize:"10px",color:"var(--brand-primary)",fontFamily:"monospace"},children:"DrawCall_Bucket_#14"})]}),(0,a.jsxs)("div",{className:"container",children:[(0,a.jsxs)(c.A,{as:"h1",className:"heroTitle_qg2I",children:["GOO",(0,a.jsx)("span",{style:{color:"var(--brand-primary)"},children:"2D"})]}),(0,a.jsx)("p",{className:"heroSubtitle_jFu1",children:e.tagline}),(0,a.jsxs)("div",{className:"buttons_AeoN",children:[(0,a.jsx)(r.A,{className:"button button--secondary button--lg",to:"/docs/core-concepts",children:"Get Started"}),(0,a.jsx)(r.A,{className:"button button--outline button--lg",to:"https://github.com/sunarya-thito/goo2d",children:"GitHub"})]})]}),(0,a.jsxs)("div",{className:"scrollIndicator_PUuy",children:[(0,a.jsx)("span",{className:"scrollText_Ze4G",children:"Scroll to explore"}),(0,a.jsx)("div",{className:"scrollLine_dBGP"})]})]})}function S({children:e}){return(0,a.jsxs)("div",{className:"codeWindow__yDo",children:[(0,a.jsxs)("div",{className:"windowHeader_PUi8",children:[(0,a.jsx)("div",{className:(0,n.A)(N,"dotRed_jHVn")}),(0,a.jsx)("div",{className:(0,n.A)(N,"dotYellow_dCsn")}),(0,a.jsx)("div",{className:(0,n.A)(N,"dotGreen_o65z")})]}),(0,a.jsx)("div",{className:"windowContent_lkH5",children:e})]})}function C(){let{siteConfig:e}=(0,o.A)();return(0,a.jsx)(l.A,{title:`${e.title} | ${e.tagline}`,description:"A low level Flutter 2D game engine",children:(0,a.jsxs)("div",{className:"pageContainer_o1Jp",children:[(0,a.jsx)(w,{}),(0,a.jsxs)("main",{children:[(0,a.jsx)(m,{}),(0,a.jsx)("section",{className:y,children:(0,a.jsx)("div",{className:"container",children:(0,a.jsxs)("div",{className:"row",style:{alignItems:"center"},children:[(0,a.jsxs)("div",{className:(0,n.A)("col col--5",v),children:[(0,a.jsx)(c.A,{as:"h2",className:f,children:"Stateful Scene Graph"}),(0,a.jsxs)("p",{className:j,children:["Build complex game worlds by stacking ",(0,a.jsx)("b",{children:"GameWidgets"}),". Goo2D leverages standard Flutter ",(0,a.jsx)("code",{children:"build"})," methods and ",(0,a.jsx)("code",{children:"sync*"})," generators to manage hierarchical entity trees."]})]}),(0,a.jsx)("div",{className:(0,n.A)("col col--7",b),children:(0,a.jsx)(S,{children:(0,a.jsx)(x.A,{language:"dart",children:`@override
Iterable<Widget> build(BuildContext context) sync* {
  yield GameWidget(
    key: const GameTag('Player'),
    components: () => [
      ObjectTransform(),
      SpriteRenderer()..sprite = playerSprite,
      PlayerController(),
    ],
  );
}`})})})]})})}),(0,a.jsx)("section",{className:y,children:(0,a.jsx)("div",{className:"container",children:(0,a.jsxs)("div",{className:"row",style:{alignItems:"center"},children:[(0,a.jsx)("div",{className:(0,n.A)("col col--7",v),children:(0,a.jsx)(S,{children:(0,a.jsx)(x.A,{language:"dart",children:`class PlayerController extends Behavior {
  @override
  void onUpdate(double dt) {
    // Decouple logic from representation
    final trans = getComponent<ObjectTransform>();
    final input = getComponent<PlayerInput>();
    
    trans.position += input.dir * 5.0 * dt;
  }
}`})})}),(0,a.jsxs)("div",{className:(0,n.A)("col col--5",b),children:[(0,a.jsx)(c.A,{as:"h2",className:f,children:"ECS"}),(0,a.jsx)("p",{className:j,children:"A flexible Entity Component System. Decouple your game logic into reusable components that can be attached and queried at runtime with ease."})]})]})})}),(0,a.jsx)("section",{className:y,children:(0,a.jsx)("div",{className:"container",children:(0,a.jsxs)("div",{className:"row",style:{alignItems:"center"},children:[(0,a.jsxs)("div",{className:(0,n.A)("col col--5",v),children:[(0,a.jsx)(c.A,{as:"h2",className:f,children:"Asset Management"}),(0,a.jsx)("p",{className:j,children:"Type-safe asset management with Enums. Built-in caching and reactive loading progress out of the box, ensuring your game assets are always organized."})]}),(0,a.jsx)("div",{className:(0,n.A)("col col--7",b),children:(0,a.jsx)(S,{children:(0,a.jsx)(x.A,{language:"dart",children:`enum MySprites with AssetEnum, TextureAssetEnum {
  ship, boss, explosion;
  @override
  AssetSource get source => 
    AssetSource.local("assets/sprites/$name.png");
}

// Reactive loading with streams
await for (final p in GameAsset.loadAll(MySprites.values)) {
  updateProgress(p.assetLoaded / p.assetCount);
}`})})})]})})}),(0,a.jsx)("section",{className:y,children:(0,a.jsx)("div",{className:"container",children:(0,a.jsxs)("div",{className:"row",style:{alignItems:"center"},children:[(0,a.jsx)("div",{className:(0,n.A)("col col--7",v),children:(0,a.jsx)(S,{children:(0,a.jsx)(x.A,{language:"dart",children:`final sheet = SpriteSheet.grid(
  texture: MySprites.explosion,
  columns: 8, rows: 8,
  ppu: 64.0,
);

// Instant frame access via coordinates
renderer.sprite = sheet[(0, 4)];`})})}),(0,a.jsxs)("div",{className:(0,n.A)("col col--5",b),children:[(0,a.jsx)(c.A,{as:"h2",className:f,children:"Sprite Sheets"}),(0,a.jsx)("p",{className:j,children:"Efficiently handle complex atlases and grids. Support for PPU (Pixels Per Unit) scaling and flexible pivot points for accurate rendering."})]})]})})}),(0,a.jsx)("section",{className:y,children:(0,a.jsx)("div",{className:"container",children:(0,a.jsxs)("div",{className:"row",style:{alignItems:"center"},children:[(0,a.jsxs)("div",{className:(0,n.A)("col col--5",v),children:[(0,a.jsx)(c.A,{as:"h2",className:f,children:"Collisions"}),(0,a.jsx)("p",{className:j,children:"Manage physical interactions without the widget tree overhead. Robust callbacks for hits, triggers, and screen-boundary events."})]}),(0,a.jsx)("div",{className:(0,n.A)("col col--7",b),children:(0,a.jsx)(S,{children:(0,a.jsx)(x.A,{language:"dart",children:`class Enemy extends Behavior with Collidable {
  @override
  void onCollision(CollisionEvent event) {
    // Precise filtering with GameTags
    if (event.other.gameObject.tag == const GameTag('Player')) {
      print("Hit player!");
      gameObject.destroy();
    }
  }
}`})})})]})})}),(0,a.jsx)("section",{className:y,children:(0,a.jsx)("div",{className:"container",children:(0,a.jsxs)("div",{className:"row",style:{alignItems:"center"},children:[(0,a.jsx)("div",{className:(0,n.A)("col col--7",v),children:(0,a.jsx)(S,{children:(0,a.jsx)(x.A,{language:"dart",children:`moveAction = createInputAction(
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
final dir = moveAction.readValue<Offset>();`})})}),(0,a.jsxs)("div",{className:(0,n.A)("col col--5",b),children:[(0,a.jsx)(c.A,{as:"h2",className:f,children:"Input System"}),(0,a.jsx)("p",{className:j,children:"Modern, action-based input system. Bind multiple physical controls to a single logical action for cross-platform support."})]})]})})}),(0,a.jsx)("section",{className:"gameDemo_M366",children:(0,a.jsx)("div",{className:"demoWrapper_oxt0",children:(0,a.jsx)("iframe",{src:"/goo2d/play/#/",width:"100%",height:"100%",style:{border:"none",background:"#000"},title:"Goo2D Demo"})})})]})]})})}}}]);