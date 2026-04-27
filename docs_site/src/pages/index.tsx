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
  return (
    <header className={clsx('hero', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className={styles.heroTitle}>
          {siteConfig.title}
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
      description="A modular ECS engine for native Flutter game development.">
      <HomepageHeader />
      <main>
        <HomepageFeatures />

        {/* SCENE GRAPH HIGHLIGHT */}
        <section className={styles.featureHighlight}>
          <div className="container">
            <div className="row" style={{ alignItems: 'center' }}>
              <div className="col col--5">
                <Heading as="h2" className={styles.highlightTitle}>Stateful Scene Graph</Heading>
                <p className={styles.highlightDescription}>
                  Build complex game worlds by stacking <b>GameWidgets</b>. Goo2D leverages 
                  standard Flutter <code>build</code> methods and <code>sync*</code> generators to manage 
                  hierarchical entity trees.
                </p>
              </div>
              <div className="col col--7">
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

        {/* ASSETS HIGHLIGHT */}
        <section className={styles.featureHighlight}>
          <div className="container">
            <div className="row" style={{ alignItems: 'center' }}>
              <div className="col col--7">
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
              <div className="col col--5">
                <Heading as="h2" className={styles.highlightTitle}>Asset Management</Heading>
                <p className={styles.highlightDescription}>
                  Type-safe asset management with Enums. Built-in caching and reactive loading
                  progress out of the box, ensuring your game assets are always organized.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* SPRITES HIGHLIGHT */}
        <section className={styles.featureHighlight}>
          <div className="container">
            <div className="row" style={{ alignItems: 'center' }}>
              <div className="col col--5">
                <Heading as="h2" className={styles.highlightTitle}>Sprite Sheets</Heading>
                <p className={styles.highlightDescription}>
                  Efficiently handle complex atlases and grids. Support for PPU (Pixels Per Unit)
                  scaling and flexible pivot points for accurate rendering.
                </p>
              </div>
              <div className="col col--7">
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
            </div>
          </div>
        </section>

        {/* COLLISION HIGHLIGHT */}
        <section className={styles.featureHighlight}>
          <div className="container">
            <div className="row" style={{ alignItems: 'center' }}>
              <div className="col col--7">
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
              <div className="col col--5">
                <Heading as="h2" className={styles.highlightTitle}>Collisions</Heading>
                <p className={styles.highlightDescription}>
                  Manage physical interactions without the widget tree overhead. Robust callbacks
                  for hits, triggers, and screen-boundary events.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* INPUT HIGHLIGHT */}
        <section className={styles.featureHighlight}>
          <div className="container">
            <div className="row" style={{ alignItems: 'center' }}>
              <div className="col col--5">
                <Heading as="h2" className={styles.highlightTitle}>Input System</Heading>
                <p className={styles.highlightDescription}>
                  Modern, action-based input system. Bind multiple physical controls to a
                  single logical action for cross-platform support.
                </p>
              </div>
              <div className="col col--7">
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
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
