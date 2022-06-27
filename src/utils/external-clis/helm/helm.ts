import {IExecuter} from '../../executer'
import {HelmInfo, HelmUpgradeObject} from './models'
import {HelmComand} from './helm-command'

class HelmImpl {
  private executer: IExecuter
  constructor(executer: IExecuter) {
    this.executer = executer
  }

  async list(namespace: string): Promise<HelmInfo[]> {
    const command: HelmComand  = new HelmComand(HelmComand.Command.LIST)
    command.namespace = namespace
    const data = await this.executer.execute(command.generate())
    const list: HelmInfo[] = JSON.parse(data)
    return list
  }

  async upgrade(upgrade: HelmUpgradeObject): Promise<string> {
    if (upgrade.repoInfo) {
      const {name, chartRepositoryUrl} = upgrade.repoInfo
      await this.repoAdd(name, chartRepositoryUrl)
    }

    const command: HelmComand  = new HelmComand(HelmComand.Command.UPGRADE)
    command.namespace = upgrade.namespace
    command.upgradeObject = upgrade
    this.executer.generateYaml(command.upgradeObject.values)
    const response = await this.executer.execute(command.generate())
    this.executer.deleteYaml()
    return response
  }

  async repoAdd(name: string, repoUrl: string): Promise<string> {
    const command: HelmComand = new HelmComand(HelmComand.Command.ADD_REPO)
    command.chartLink = repoUrl
    command.name = name
    return this.executer.execute(command.generate())
  }

  async uninstall(name: string, namespace: string): Promise<string> {
    const installedRepos: HelmInfo[] = await this.list(namespace)

    if (installedRepos.some(x => x.name === name)) {
      const command: HelmComand = new HelmComand(HelmComand.Command.UNINSTALL)
      command.name = name
      command.namespace = namespace
      return this.executer.execute(command.generate())
    }

    return `Release: '${name}' not found in namespace: '${namespace}'`
  }
}

export interface IHelm {
  /**
   * List Helm releases
   * @param namespace The namespace to search releases on.
   * @returns A promise containing a list of releases as a HelmInfo array.
   */
  list(namespace: string): Promise<HelmInfo[]>;
  /**
   * Upgrade or install a release.
   * @param upgrade Object containing the information necessary to upgrade/install a release.
   * If a RepoInfo object is found inside, will add the repository before upgrade/install.
   * @returns A promise containing the 'upgrade' default output from Helm.
   */
  upgrade(upgrade: HelmUpgradeObject): Promise<string>;
    /**
   * Add a chart repository.
   * @param name The name you wish to give to the repository.
   * @param repoUrl The URL to the chart repository
   * @returns A promise containing the 'repo add' default output from Helm.
   */
  repoAdd(name: string, repoUrl: string): Promise<string>;
  /**
   * Uninstall a release.
   * @param name The name of the release.
   * @param namespace The namespace to find the release on.
   * @returns A promise containing the 'uninstall' default output from Helm.
   */
  uninstall(name: string, namespace: string): Promise<string>;
}

export class Helm extends HelmImpl implements IHelm {}
