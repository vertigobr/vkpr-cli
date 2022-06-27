import util = require('node:util')
import cp = require('node:child_process')
const exec = util.promisify(cp.exec)
import fs = require('fs')
import yaml = require('js-yaml');
import os = require('os')

class ExecuterImpl {
  async execute(command: string): Promise<string> {
    const {stdout, stderr} = await exec(command)
    if (stderr) console.error('stderr:', stderr)
    return stdout
  }

  async generateYaml(obj: any): Promise<string> {
    const name = `${os.homedir()}/.vkpr/__vkpr_values.yaml`
    fs.writeFile(name, yaml.dump(obj), err => {
      if (err) console.log(err)
    })
    return name
  }

  deleteYaml(): void {
    const name = `${os.homedir()}/.vkpr/__vkpr_values.yaml`
    fs.unlink(name, err => {
      if (err) console.log(err)
    })
  }
}

export interface IExecuter {
  execute(command: string): Promise<string>;
  generateYaml(obj: any): Promise<string>;
  deleteYaml(): void;
}

export class Executer extends ExecuterImpl implements IExecuter {}
