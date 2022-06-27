export interface HelmInfo {
  name: string,
  namespace: string,
  revision: string,
  updated: string,
  status: string,
  chart: string,
  appVersion: string
}

export interface HelmUpgradeObject {
  chartVersion: string,
  namespace: string,
  values: any,
  releaseName: string,
  chartRepository: string
  repoInfo?: RepoInfo
}

interface RepoInfo {
  name: string,
  chartRepositoryUrl: string
}
