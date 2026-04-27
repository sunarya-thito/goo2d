import React, { useState, useEffect, useRef } from 'react';
import type { ReactNode } from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';
import Heading from '@theme/Heading';
import CodeBlock from '@theme/CodeBlock';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

import styles from './index.module.css';

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  
  // Interactive Simulation State
  const [shipPos, setShipPos] = useState({ x: 70, y: 30 });
  const [collidingZones, setCollidingZones] = useState({ zone04: false, zone12: false, zone07: false });
  const [rotation, setRotation] = useState(0);
  
  const shipRef = useRef<HTMLDivElement>(null);
  const z04Ref = useRef<HTMLDivElement>(null);
  const z12Ref = useRef<HTMLDivElement>(null);
  const z07Ref = useRef<HTMLDivElement>(null);

  const checkCollision = (rect1: DOMRect, rect2: DOMRect) => {
    return !(rect1.right < rect2.left || 
             rect1.left > rect2.right || 
             rect1.bottom < rect2.top || 
             rect1.top > rect2.bottom);
  };

  useEffect(() => {
    let frameId: number;
    const startTime = performance.now();
    
    const update = (time: number) => {
      const elapsed = (time - startTime) / 1000;
      
      const nextX = 50 + Math.cos(elapsed * 0.4) * 35 + Math.sin(elapsed * 0.1) * 5;
      const nextY = 45 + Math.sin(elapsed * 0.5) * 30 + Math.cos(elapsed * 0.1) * 5;

      const dx = -0.4 * Math.sin(elapsed * 0.4) * 35 + 0.1 * Math.cos(elapsed * 0.1) * 5;
      const dy = 0.5 * Math.cos(elapsed * 0.5) * 30 - 0.1 * Math.sin(elapsed * 0.1) * 5;
      
      const targetRot = Math.atan2(dy, dx) * (180 / Math.PI) + 90;
      setRotation(prev => {
        let diff = targetRot - prev;
        while (diff < -180) diff += 360;
        while (diff > 180) diff -= 360;
        return prev + diff * 0.1;
      });

      setShipPos({ x: nextX, y: nextY });

      // Precise collision detection using DOM Rects
      if (shipRef.current) {
        const shipRect = shipRef.current.getBoundingClientRect();
        setCollidingZones({
          zone04: z04Ref.current ? checkCollision(shipRect, z04Ref.current.getBoundingClientRect()) : false,
          zone12: z12Ref.current ? checkCollision(shipRect, z12Ref.current.getBoundingClientRect()) : false,
          zone07: z07Ref.current ? checkCollision(shipRect, z07Ref.current.getBoundingClientRect()) : false
        });
      }

      frameId = requestAnimationFrame(update);
    };
    frameId = requestAnimationFrame(update);
    return () => cancelAnimationFrame(frameId);
  }, []);
  const dartCodeSnippet = `
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
  `.repeat(4);
  
  // Create a wide block of code by repeating the snippet horizontally but offset each line
  const wideCodeSnippet = dartCodeSnippet.split('\n').map((line, i) => (line + " ".repeat(20)).repeat(4).substring(i % 12)).join('\n');

  const isAnyColliding = Object.values(collidingZones).some(v => v);

  return (
    <header className={clsx('hero', styles.heroBanner)}>
      <div className={styles.noise} />
      <div className={styles.scanlines} />
      <div className={styles.codeBackground}>{wideCodeSnippet}</div>
      
      {/* Frame Time Monitor (Technical & Animated) */}
      <div className={styles.perfGraph}>
        <div style={{ fontSize: '10px', color: 'var(--brand-primary)', marginBottom: '8px', fontFamily: 'monospace', letterSpacing: '0.1em' }}>FRAME_TIME (ms) [ACTIVE]</div>
        <div style={{ display: 'flex', alignItems: 'flex-end', height: '80px', gap: '4px', borderLeft: '1px solid var(--brand-primary)', borderBottom: '1px solid var(--brand-primary)', padding: '4px' }}>
          {[...Array(30)].map((_, i) => (
            <div 
              key={i} 
              className={styles.perfBar}
              style={{ 
                flex: 1,
                height: `${[16, 17, 16, 18, 16, 16, 32, 16, 17, 16, 16, 19, 16, 16, 16, 24, 16, 16, 16, 17, 16, 16, 16, 16, 16, 18, 16, 16, 20, 16][i]}px`, 
                backgroundColor: i === 6 || i === 15 || i === 28 ? '#13b9fd' : 'var(--brand-primary)',
                opacity: 0.7,
                animationDelay: `${(i * 0.05) % 0.3}s`,
                animationDuration: `${0.1 + (i % 3) * 0.05}s`,
                transformOrigin: 'bottom'
              }} 
            />
          ))}
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '4px', fontSize: '8px', color: 'var(--brand-primary)', fontFamily: 'monospace' }}>
          <span>0ms</span>
          <span>16.6ms (60fps)</span>
        </div>
      </div>

      {/* Technical Sprite: SVG Ship (Animated Movement) */}
      <div 
        ref={shipRef}
        style={{ 
          position: 'absolute', 
          left: `${shipPos.x}%`, 
          top: `${shipPos.y}%`, 
          width: '80px',
          height: '80px',
          zIndex: 1, 
          pointerEvents: 'none', 
          opacity: 0.8,
          transform: 'translate(-50%, -50%)',
        }}
      >
        {/* Only rotate the ship body, not the label */}
        <div style={{ 
          width: '100%',
          height: '100%',
          transform: `rotate(${rotation}deg)`,
          transition: 'transform 0.1s linear'
        }}>
          <svg width="100%" height="100%" viewBox="0 0 100 100" style={{ filter: 'drop-shadow(0 0 10px rgba(1, 117, 194, 0.4))' }}>
            {/* Ship Body */}
            <path d="M50 10 L85 85 L50 70 L15 85 Z" fill="rgba(255, 255, 255, 0.9)" stroke="var(--brand-primary)" strokeWidth="3" />
            {/* Cockpit */}
            <path d="M50 25 L65 60 L50 50 L35 60 Z" fill="var(--brand-primary)" opacity="0.6" />
            {/* Thrusters */}
            <rect x="42" y="75" width="16" height="10" fill="var(--brand-primary)" opacity="0.4">
              <animate attributeName="opacity" values="0.4;1;0.4" dur="0.2s" repeatCount="indefinite" />
            </rect>
          </svg>
        </div>
        
        {/* Upright Label - Perfect Circle Hitbox */}
        <div style={{ 
          position: 'absolute', 
          inset: '-10px', 
          border: '1px dashed var(--brand-primary)', 
          backgroundColor: isAnyColliding ? 'rgba(1, 117, 194, 0.2)' : 'transparent',
          borderRadius: '50%', 
          opacity: 0.8,
          aspectRatio: '1/1' 
        }}>
          <span style={{ position: 'absolute', bottom: '-20px', left: '50%', transform: 'translateX(-50%)', color: 'var(--brand-primary)', fontSize: '9px', fontFamily: 'monospace', whiteSpace: 'nowrap', fontWeight: 'bold' }}>
            ● {isAnyColliding ? 'COLLISION_DETECTED' : 'CIRCLE_COLLIDER'}
          </span>
        </div>
      </div>

      {/* Multiple Trigger Zones */}
      <div ref={z04Ref} className={clsx(collidingZones.zone04 && styles.triggerActive)} style={{ position: 'absolute', bottom: '15%', right: '10%', width: '160px', height: '160px', border: '1px dashed rgba(1, 117, 194, 0.4)', backgroundColor: 'rgba(1, 117, 194, 0.02)', zIndex: 1, pointerEvents: 'none', opacity: 0.8 }}>
        <div className={clsx(collidingZones.zone04 && styles.triggerActiveLabel)} style={{ position: 'absolute', top: '0', left: '0', padding: '2px 6px', background: 'rgba(1, 117, 194, 0.3)', color: 'white', fontSize: '9px', fontFamily: 'monospace' }}>TRIGGER_ZONE_#04</div>
        <div style={{ position: 'absolute', bottom: '6px', right: '6px', color: 'var(--brand-primary)', fontSize: '10px', fontFamily: 'monospace', opacity: 0.6 }}>OnOverlap: notify()</div>
      </div>
      
      <div ref={z12Ref} className={clsx(collidingZones.zone12 && styles.triggerActive)} style={{ position: 'absolute', top: '20%', left: '30%', width: '100px', height: '100px', border: '1px dashed rgba(1, 117, 194, 0.3)', zIndex: 1, pointerEvents: 'none', opacity: 0.5 }}>
        <div className={clsx(collidingZones.zone12 && styles.triggerActiveLabel)} style={{ position: 'absolute', top: '0', left: '0', padding: '1px 4px', background: 'rgba(1, 117, 194, 0.2)', color: 'white', fontSize: '8px', fontFamily: 'monospace' }}>EVENT_TRGR_#12</div>
      </div>

      <div ref={z07Ref} className={clsx(collidingZones.zone07 && styles.triggerActive)} style={{ position: 'absolute', top: '60%', left: '15%', width: '120px', height: '120px', border: '1px dashed rgba(1, 117, 194, 0.3)', zIndex: 1, pointerEvents: 'none', opacity: 0.5 }}>
        <div className={clsx(collidingZones.zone07 && styles.triggerActiveLabel)} style={{ position: 'absolute', top: '0', left: '0', padding: '1px 4px', background: 'rgba(1, 117, 194, 0.2)', color: 'white', fontSize: '8px', fontFamily: 'monospace' }}>AREA_TRGR_#07</div>
      </div>

      {/* Texture Atlas Mockup (More Visible) */}
      <div style={{ position: 'absolute', top: '15%', right: '5%', display: 'grid', gridTemplateColumns: 'repeat(4, 30px)', gap: '6px', opacity: 0.6, zIndex: 2 }}>
        {[...Array(16)].map((_, i) => (
          <div key={i} style={{ width: '30px', height: '30px', border: '1px solid var(--brand-primary)', background: i % 5 === 0 ? 'rgba(1, 117, 194, 0.4)' : 'transparent' }} />
        ))}
        <div style={{ gridColumn: 'span 4', fontSize: '10px', color: 'var(--brand-primary)', marginTop: '8px', fontFamily: 'monospace', fontWeight: 'bold' }}>TEXTURE_ATLAS_01</div>
      </div>

      <div className={styles.viewportInfo}>
        <div>FPS: 60.0</div>
        <div>Delta: 16.6ms</div>
        <div>VRAM: 124MB</div>
        <div>Draws: 12</div>
      </div>

      <div className={styles.viewportCoords}>
        viewport: 0,0,1920,1080
      </div>

      {/* Technical Game Elements (Wireframes) - Scaled & Spread Out */}
      <div className={styles.floatingShape} style={{ width: '220px', height: '220px', left: '2%', top: '10%', animationDelay: '0s', opacity: 0.5 }}>
        <div className={styles.wireframeBox} />
        <span style={{ position: 'absolute', top: '-30px', left: '0', fontSize: '12px', color: 'var(--brand-primary)', fontFamily: 'monospace', fontWeight: 'bold' }}>VertexData_Buffer</span>
      </div>
      <div className={styles.floatingShape} style={{ width: '160px', height: '160px', left: '88%', top: '20%', animationDelay: '-5s', opacity: 0.4 }}>
        <div className={styles.wireframeBox} />
        <span style={{ position: 'absolute', top: '-30px', left: '0', fontSize: '12px', color: 'var(--brand-primary)', fontFamily: 'monospace', fontWeight: 'bold' }}>SpriteBatcher_01</span>
      </div>
      <div className={styles.floatingShape} style={{ width: '190px', height: '190px', left: '5%', top: '75%', animationDelay: '-12s', opacity: 0.4 }}>
        <div className={styles.wireframeBox} />
        <span style={{ position: 'absolute', top: '-30px', left: '0', fontSize: '12px', color: 'var(--brand-primary)', fontFamily: 'monospace', fontWeight: 'bold' }}>Texture_Slot#02</span>
      </div>
      <div className={styles.floatingShape} style={{ width: '130px', height: '130px', left: '80%', top: '65%', animationDelay: '-8s', opacity: 0.1 }}>
        <div className={styles.wireframeBox} />
        <span style={{ position: 'absolute', top: '-25px', left: '0', fontSize: '10px', color: 'var(--brand-primary)', fontFamily: 'monospace' }}>GPU_Resource_HNDL</span>
      </div>
      <div className={styles.floatingShape} style={{ width: '100px', height: '100px', left: '40%', top: '5%', animationDelay: '-15s', opacity: 0.1 }}>
        <div className={styles.wireframeBox} />
        <span style={{ position: 'absolute', top: '-25px', left: '0', fontSize: '10px', color: 'var(--brand-primary)', fontFamily: 'monospace' }}>Shader_Program_Cache</span>
      </div>
      <div className={styles.floatingShape} style={{ width: '140px', height: '140px', left: '15%', top: '40%', animationDelay: '-2s', opacity: 0.08 }}>
        <div className={styles.wireframeBox} />
        <span style={{ position: 'absolute', top: '-25px', left: '0', fontSize: '10px', color: 'var(--brand-primary)', fontFamily: 'monospace' }}>DrawCall_Bucket_#14</span>
      </div>

      <div className="container">
        <Heading as="h1" className={styles.heroTitle}>
          GOO<span style={{ color: 'var(--brand-primary)' }}>2D</span>
        </Heading>
        <p className={styles.heroSubtitle}>{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/core-concepts">
            Get Started
          </Link>
          <Link
            className="button button--outline button--lg"
            to="https://github.com/sunarya-thito/goo2d">
            GitHub
          </Link>
        </div>
      </div>

      <div className={styles.scrollIndicator}>
        <span className={styles.scrollText}>Scroll to explore</span>
        <div className={styles.scrollLine}></div>
      </div>
    </header>
  );
}

function CodeWindow({ children }: { children: ReactNode }) {
  return (
    <div className={styles.codeWindow}>
      <div className={styles.windowHeader}>
        <div className={clsx(styles.dot, styles.dotRed)} />
        <div className={clsx(styles.dot, styles.dotYellow)} />
        <div className={clsx(styles.dot, styles.dotGreen)} />
      </div>
      <div className={styles.windowContent}>
        {children}
      </div>
    </div>
  );
}

export default function Home(): ReactNode {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title} | ${siteConfig.tagline}`}
      description="A low level Flutter 2D game engine">
      <div className={styles.pageContainer}>
        <HomepageHeader />
        <main>
          <HomepageFeatures />

          {/* 1. SCENE GRAPH HIGHLIGHT - Text Left, Code Right */}
          <section className={styles.featureHighlight}>
            <div className="container">
              <div className="row" style={{ alignItems: 'center' }}>
                <div className={clsx("col col--5", styles.colLeft)}>
                  <Heading as="h2" className={styles.highlightTitle}>Stateful Scene Graph</Heading>
                  <p className={styles.highlightDescription}>
                    Build complex game worlds by stacking <b>GameWidgets</b>. Goo2D leverages
                    standard Flutter <code>build</code> methods and <code>sync*</code> generators to manage
                    hierarchical entity trees.
                  </p>
                </div>
                <div className={clsx("col col--7", styles.colRight)}>
                  <CodeWindow>
                    <CodeBlock language="dart">
                      {`@override
Iterable<Widget> build(BuildContext context) sync* {
  yield GameWidget(
    key: const GameTag('Player'),
    components: () => [
      ObjectTransform(),
      SpriteRenderer()..sprite = playerSprite,
      PlayerController(),
    ],
  );
}`}
                    </CodeBlock>
                  </CodeWindow>
                </div>
              </div>
            </div>
          </section>

          {/* 2. ECS HIGHLIGHT - Code Left, Text Right */}
          <section className={styles.featureHighlight}>
            <div className="container">
              <div className="row" style={{ alignItems: 'center' }}>
                <div className={clsx("col col--7", styles.colLeft)}>
                  <CodeWindow>
                    <CodeBlock language="dart">
                      {`class PlayerController extends Behavior {
  @override
  void onUpdate(double dt) {
    // Decouple logic from representation
    final trans = getComponent<ObjectTransform>();
    final input = getComponent<PlayerInput>();
    
    trans.position += input.dir * 5.0 * dt;
  }
}`}
                    </CodeBlock>
                  </CodeWindow>
                </div>
                <div className={clsx("col col--5", styles.colRight)}>
                  <Heading as="h2" className={styles.highlightTitle}>ECS</Heading>
                  <p className={styles.highlightDescription}>
                    A flexible Entity Component System. Decouple your game logic into
                    reusable components that can be attached and queried at runtime with ease.
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* 3. ASSETS HIGHLIGHT - Text Left, Code Right */}
          <section className={styles.featureHighlight}>
            <div className="container">
              <div className="row" style={{ alignItems: 'center' }}>
                <div className={clsx("col col--5", styles.colLeft)}>
                  <Heading as="h2" className={styles.highlightTitle}>Asset Management</Heading>
                  <p className={styles.highlightDescription}>
                    Type-safe asset management with Enums. Built-in caching and reactive loading
                    progress out of the box, ensuring your game assets are always organized.
                  </p>
                </div>
                <div className={clsx("col col--7", styles.colRight)}>
                  <CodeWindow>
                    <CodeBlock language="dart">
                      {`enum MySprites with AssetEnum, TextureAssetEnum {
  ship, boss, explosion;
  @override
  AssetSource get source => 
    AssetSource.local("assets/sprites/\$name.png");
}

// Reactive loading with streams
await for (final p in GameAsset.loadAll(MySprites.values)) {
  updateProgress(p.assetLoaded / p.assetCount);
}`}
                    </CodeBlock>
                  </CodeWindow>
                </div>
              </div>
            </div>
          </section>

          {/* 4. SPRITES HIGHLIGHT - Code Left, Text Right */}
          <section className={styles.featureHighlight}>
            <div className="container">
              <div className="row" style={{ alignItems: 'center' }}>
                <div className={clsx("col col--7", styles.colLeft)}>
                  <CodeWindow>
                    <CodeBlock language="dart">
                      {`final sheet = SpriteSheet.grid(
  texture: MySprites.explosion,
  columns: 8, rows: 8,
  ppu: 64.0,
);

// Instant frame access via coordinates
renderer.sprite = sheet[(0, 4)];`}
                    </CodeBlock>
                  </CodeWindow>
                </div>
                <div className={clsx("col col--5", styles.colRight)}>
                  <Heading as="h2" className={styles.highlightTitle}>Sprite Sheets</Heading>
                  <p className={styles.highlightDescription}>
                    Efficiently handle complex atlases and grids. Support for PPU (Pixels Per Unit)
                    scaling and flexible pivot points for accurate rendering.
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* 5. COLLISION HIGHLIGHT - Text Left, Code Right */}
          <section className={styles.featureHighlight}>
            <div className="container">
              <div className="row" style={{ alignItems: 'center' }}>
                <div className={clsx("col col--5", styles.colLeft)}>
                  <Heading as="h2" className={styles.highlightTitle}>Collisions</Heading>
                  <p className={styles.highlightDescription}>
                    Manage physical interactions without the widget tree overhead. Robust callbacks
                    for hits, triggers, and screen-boundary events.
                  </p>
                </div>
                <div className={clsx("col col--7", styles.colRight)}>
                  <CodeWindow>
                    <CodeBlock language="dart">
                      {`class Enemy extends Behavior with Collidable {
  @override
  void onCollision(CollisionEvent event) {
    // Precise filtering with GameTags
    if (event.other.gameObject.tag == const GameTag('Player')) {
      print("Hit player!");
      gameObject.destroy();
    }
  }
}`}
                    </CodeBlock>
                  </CodeWindow>
                </div>
              </div>
            </div>
          </section>

          {/* 6. INPUT HIGHLIGHT - Code Left, Text Right */}
          <section className={styles.featureHighlight}>
            <div className="container">
              <div className="row" style={{ alignItems: 'center' }}>
                <div className={clsx("col col--7", styles.colLeft)}>
                  <CodeWindow>
                    <CodeBlock language="dart">
                      {`moveAction = createInputAction(
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
final dir = moveAction.readValue<Offset>();`}
                    </CodeBlock>
                  </CodeWindow>
                </div>
                <div className={clsx("col col--5", styles.colRight)}>
                  <Heading as="h2" className={styles.highlightTitle}>Input System</Heading>
                  <p className={styles.highlightDescription}>
                    Modern, action-based input system. Bind multiple physical controls to a
                    single logical action for cross-platform support.
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* INTERACTIVE DEMO */}
          <section className={styles.gameDemo}>
            <div className={styles.demoWrapper}>
              <iframe
                src="/goo2d/play/#/"
                width="100%"
                height="100%"
                style={{ border: 'none', background: '#000' }}
                title="Goo2D Demo"
              />
            </div>
          </section>
        </main>
      </div>
    </Layout>
  );
}
