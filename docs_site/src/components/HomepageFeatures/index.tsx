import type { ReactNode } from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import CodeBlock from '@theme/CodeBlock';
import styles from './styles.module.css';

type FeatureItem = {
  id: string;
  title: string;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    id: '01',
    title: 'Stateful Scene Graph',
    description: (
      <>
        Build your game tree using standard Flutter widgets and <code>sync*</code> generators.
        Manage complex entity lifecycles with the familiar <code>StatefulGameWidget</code> pattern.
      </>
    ),
  },
  {
    id: '02',
    title: 'Entity-Component-System (ECS)',
    description: (
      <>
        A flexible Entity Component System. Decouple your game logic into
        reusable components that can be attached and queried at runtime with ease.
      </>
    ),
  },
  {
    id: '03',
    title: 'Action-Based Input',
    description: (
      <>
        Decouple game logic from physical hardware. Bind multiple keys or touch controls to
        logical actions, with built-in support for composite vectors and deadzones.
      </>
    ),
  },
];

function Feature({ id, title, description }: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className={styles.featureCard}>
        <span className={styles.featureId}>{id}</span>
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
