import {HelmUpgradeObject} from './models'

export class HelmComand {
  private _command: HelmComand.Command;
  private _namespace?: string;
  private _name?: string;
  private _chartLink?: string;
  private _upgradeObject?: HelmUpgradeObject;

  readonly cli = 'helm'
  readonly outputType = '-o json'

  constructor(command: HelmComand.Command) {
    this._command = command
  }

  public get name(): string | undefined {
    return this._name
  }

  public set name(name: string | undefined) {
    this._name = name
  }

  public get chartLink(): string | undefined {
    return this._chartLink
  }

  public set chartLink(chartLink: string | undefined) {
    this._chartLink = chartLink
  }

  public get upgradeObject(): HelmUpgradeObject | undefined {
    return this._upgradeObject
  }

  public set upgradeObject(obj: HelmUpgradeObject | undefined) {
    this._upgradeObject = obj
  }

  public get command(): HelmComand.Command {
    return this._command
  }

  public set command(command: HelmComand.Command) {
    this._command = command
  }

  public get namespace(): string | undefined {
    return this._namespace
  }

  public set namespace(namespace: string | undefined) {
    this._namespace = namespace
  }

  public generate(): string {
    const base = `${this.cli} ${this._command}`
    switch (this._command) {
    case (HelmComand.Command.LIST):
      return `${base} -n ${this._namespace} ${this.outputType}`
    case (HelmComand.Command.UPGRADE):
      return `${base} -i --version ${this._upgradeObject?.chartVersion} --create-namespace --namespace ${this._upgradeObject?.namespace} --wait -f ~/.vkpr/__vkpr_values.yaml ${this._upgradeObject?.releaseName} ${this._upgradeObject?.chartRepository}`
    case (HelmComand.Command.ADD_REPO):
      return `${base} ${this._name} ${this._chartLink} --force-update`
    case (HelmComand.Command.UNINSTALL):
      return `${base} ${this._name} -n ${this._namespace}`
    }
  }
}

export namespace HelmComand {
  export enum Command {
    LIST = 'list',
    UPGRADE = 'upgrade',
    ADD_REPO = 'repo add',
    UNINSTALL = 'uninstall'
  }
}

