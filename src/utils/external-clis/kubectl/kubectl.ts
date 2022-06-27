import {V1Namespace, KubeConfig, CoreV1Api} from '@kubernetes/client-node'
import {Namespace, Pod, Secret, Status} from './models'

class KubectlImpl {
  private kc: KubeConfig = new KubeConfig();

  async getPods(namespace?: string): Promise<Pod[]> {
    this.kc.loadFromDefault()
    const k8sApi: CoreV1Api = this.kc.makeApiClient(CoreV1Api)
    const res = namespace === undefined ? await k8sApi.listPodForAllNamespaces() : await k8sApi.listNamespacedPod(namespace)

    return res.body.items.map(pod => {
      const labels = pod.metadata?.labels || {}
      const name = pod.metadata?.name || ''
      const ns = pod.metadata?.namespace || ''
      return {name: name, labels: labels, namespace: ns}
    })
  }

  async createNamespace(name: string): Promise<Namespace> {
    this.kc.loadFromDefault()
    const k8sApi: CoreV1Api = this.kc.makeApiClient(CoreV1Api)
    const namespaceToCreate: V1Namespace = {metadata: {name: name}}
    const namespacesInTheCluster: V1Namespace[] = (await k8sApi.listNamespace()).body.items
    const namespaceExists = namespacesInTheCluster.some(n => n.metadata?.name === name)

    if (!namespaceExists) {
      const createdNamespace = await k8sApi.createNamespace(namespaceToCreate)
      return {name: createdNamespace.body.metadata?.name || ''}
    }

    const namespaceAlreadyInTheCluster = namespacesInTheCluster.find(n => n.metadata?.name === name)
    return {name: namespaceAlreadyInTheCluster?.metadata?.name || ''}
  }

  async getSecrets(namespace?: string): Promise<Secret[]> {
    this.kc.loadFromDefault()
    const k8sApi: CoreV1Api = this.kc.makeApiClient(CoreV1Api)
    const res = namespace === undefined ? await k8sApi.listSecretForAllNamespaces() : await k8sApi.listNamespacedSecret(namespace)

    return res.body.items.map(secret => {
      const name = secret.metadata?.name || ''
      const ns = secret.metadata?.namespace || ''
      const labels = secret.metadata?.labels || {}
      const data = secret.data || {}
      return {name: name, namespace: ns, labels: labels, data: data}
    })
  }

  async deleteSecret(name: string, namespace: string): Promise<Status> {
    this.kc.loadFromDefault()
    const k8sApi: CoreV1Api = this.kc.makeApiClient(CoreV1Api)

    try {
      const res = await k8sApi.deleteNamespacedSecret(name, namespace)
      const {status, message, reason} = res.body
      return {status: status, message: message, reason: reason}
    } catch (error:any) {
      const {status, message, reason} = error.body
      return {status: status, message: message, reason: reason}
    }
  }
}

interface IKubectl {
  /**
   * Search and list pods in the cluster.
   * @param namespace The namespace to search pods on. If no namespace is given, will search through all namespaces.
   * @returns A promise containing a list of pods.
   */
  getPods(namespace?: string): Promise<Pod[]>;
  /**
  * Create a namespace with the given name.
  * @param name The name of the namespace to be created.
  * @returns A promise containing the namespace created. If it already exists, retrieve said namespace.
  */
  createNamespace(name: string): Promise<Namespace>;
  /**
   * Search and list secrets in the cluster.
   * @param namespace The namespace to search secrets on. If no namespace is given, will search through all namespaces.
   * @returns A promise containing a list of secrets.
   */
  getSecrets(namespace?: string): Promise<Secret[]>;
  /**
   * Delete secrets in the cluster.
   * @param name The name of the secret to be deleted.
   * @param namespace The namespace to search the secret on.
   * @returns The status of the transaction.
   */
  deleteSecret(name: string, namespace: string): Promise<Status>;
}

class Kubectl extends KubectlImpl implements IKubectl {}

export const kubectl: IKubectl = new Kubectl()
