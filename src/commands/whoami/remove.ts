import {Command} from '@oclif/core'
import {Executer, IExecuter} from '../../utils/executer'
import {Helm, IHelm} from '../../utils/external-clis/helm/helm'
import chalk = require('chalk')

export default class Remove extends Command {
  private executer: IExecuter = new Executer()
  private helm: IHelm = new Helm(this.executer)
  static description = 'Remove the Whoami application'

  static flags = {}

  static args = []

  async run(): Promise<void> {
    const log = console.log
    log(chalk.green('\n=========== Initializing VKPR Uninstall routine ===================\n'))
    const res = await this.helm.uninstall('whoami', 'vkpr')
    if (res.includes('uninstalled')) {
      log(chalk.green(res))
    } else {
      log(chalk.red(res))
    }
  }
}
