import {Command, Flags} from '@oclif/core'
import {Executer, IExecuter} from '../../utils/executer'
import {Helm, IHelm} from '../../utils/external-clis/helm/helm'
import {HelmUpgradeObject} from '../../utils/external-clis/helm/models'
import {chartInfo} from '../../values/info'
import {whoamiDefaultValues, whoAmiTlsValues, WhoamiValues} from '../../values/whoami/whoami-values'
import {prompt} from 'inquirer'
import chalk = require('chalk')

export default class Install extends Command {
  private executer: IExecuter = new Executer()
  private helm: IHelm = new Helm(this.executer)
  static description = 'Install the Whoami application'

  static flags = {
    secure: Flags.boolean({char: 's', description: 'Activate tls'}),
    domain: Flags.string({description: 'The whoami domain'}),
  }

  static args = []

  async run(): Promise<void> {
    const log = console.log
    log(chalk.green('\n=========== Initializing VKPR Install routine ===================\n'))
    const {flags} = await this.parse(Install)

    const answers = await prompt<{[key: string]: any}>([
      {
        when: !flags.secure,
        type: 'list',
        name: 'secure',
        message: 'Secure?',
        choices: ['false', 'true'],
        default: 'no',
      },
      {
        when: !flags.domain,
        type: 'string',
        name: 'domain',
        message: 'Type the Whoami domain: ',
        default: 'localhost',
      },
    ])

    log(chalk.white('\nSetting up local variables...'))
    // parse the variables
    const variables: Variables = this.parseVariables(flags, answers)
    // choose best value obj to use based on the variables
    const values: WhoamiValues = this.chooseValue(variables)
    // update values object based on the variables
    const updatedValues: WhoamiValues = this.updateValues(variables, values)

    const options: HelmUpgradeObject = {
      chartVersion: chartInfo.whoami.version,
      namespace: 'vkpr',
      values: updatedValues,
      releaseName: 'whoami',
      chartRepository: 'cowboysysop/whoami',
      repoInfo: {
        name: 'cowboysysop',
        chartRepositoryUrl: chartInfo.whoami.chartRepositoryUrl,
      },
    }

    log(chalk.white('Installing the Whoami Application...'))
    await this.helm.upgrade(options)

    log(chalk.green('Sucess!'))
  }

  private parseVariables(flags: any, answers: any): {domain: string, isSecure: boolean} {
    return {domain: flags.domain || answers.domain, isSecure: flags.secure || answers.secure === 'true'}
  }

  private chooseValue(variables: Variables): WhoamiValues {
    return variables.isSecure ? whoAmiTlsValues : whoamiDefaultValues
  }

  private updateValues(variables: Variables, values: WhoamiValues): WhoamiValues {
    const {domain, isSecure}: Variables = variables

    const valuesToReturn: WhoamiValues = values

    valuesToReturn.ingress.hosts[0] = {...values.ingress.hosts[0], host: `whoami.${domain}`}

    if (isSecure) {
      valuesToReturn.ingress.tls[0].hosts.push(`whoami.${domain}`)
    }

    valuesToReturn.ingress.annotations = {...values.ingress.annotations, 'kubernetes.io/ingress.class': 'nginx'}

    return valuesToReturn
  }
}

interface Variables {
  domain: string,
  isSecure: boolean
}
