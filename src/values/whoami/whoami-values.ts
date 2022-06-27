export interface WhoamiValues {
    ingress:   Ingress;
    podLabels: Record<string, unknown>;
}

interface Ingress {
    [key: string]: any
    enabled:     boolean;
    annotations:  Record<string, unknown>;
    hosts:       Host[];
    pathType:    string;
}

interface Host {
    paths: string[];
    host?: string;
}

export const whoamiDefaultValues: WhoamiValues = {
  ingress: {
    enabled: true,
    annotations: {
      'kubernetes.io/ingress.class': 'nginx',
    },
    hosts: [
      {
        paths: [
          '/',
        ],
      },
    ],
    pathType: 'Prefix',
  },
  podLabels: {
    'app.kubernetes.io/managed-by': 'vkpr',
  },
}

const whoAmiTslSetup: WhoamiValues = whoamiDefaultValues

const tls = {hosts: [], secretName: 'whoami-cert'}
whoAmiTslSetup.ingress.annotations = {...whoamiDefaultValues.ingress.annotations, 'kubernetes.io/tls-acme': 'true'}
whoAmiTslSetup.ingress.tls = []
whoAmiTslSetup.ingress.tls.push(tls)

export const whoAmiTlsValues: WhoamiValues = whoAmiTslSetup
