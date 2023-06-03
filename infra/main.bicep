targetScope = 'subscription'

param name string
param location string = 'Korea Central'
param env string = 'dev'

param apiManagementPublisherName string
param apiManagementPublisherEmail string

var locationCodeMap = {
  australiacentral: 'auc'
  'Australia Central': 'auc'
  australiaeast: 'aue'
  'Australia East': 'aue'
  australiasoutheast: 'ause'
  'Australia Southeast': 'ause'
  brazilsouth: 'brs'
  'Brazil South': 'brs'
  canadacentral: 'cac'
  'Canada Central': 'cac'
  canadaeast: 'cae'
  'Canada East': 'cae'
  centralindia: 'cin'
  'Central India': 'cin'
  centralus: 'cus'
  'Central US': 'cus'
  eastasia: 'ea'
  'East Asia': 'ea'
  eastus: 'eus'
  'East US': 'eus'
  eastus2: 'eus2'
  'East US 2': 'eus2'
  francecentral: 'frc'
  'France Central': 'frc'
  germanywestcentral: 'dewc'
  'Germany West Central': 'dewc'
  japaneast: 'jpe'
  'Japan East': 'jpe'
  japanwest: 'jpw'
  'Japan West': 'jpw'
  jioindianorthwest: 'jinw'
  'Jio India North West': 'jinw'
  koreacentral: 'krc'
  'Korea Central': 'krc'
  koreasouth: 'krs'
  'Korea South': 'krs'
  northcentralus: 'ncus'
  'North Central US': 'ncus'
  northeurope: 'neu'
  'North Europe': 'neu'
  norwayeast: 'noe'
  'Norway East': 'noe'
  southafricanorth: 'zan'
  'South Africa North': 'zan'
  southcentralus: 'scus'
  'South Central US': 'scus'
  southindia: 'sin'
  'South India': 'sin'
  southeastasia: 'sea'
  'Southeast Asia': 'sea'
  swedencentral: 'sec'
  'Sweden Central': 'sec'
  switzerlandnorth: 'chn'
  'Switzerland North': 'chn'
  uaenorth: 'uaen'
  'UAE North': 'uaen'
  uksouth: 'uks'
  'UK South': 'uks'
  ukwest: 'ukw'
  'UK West': 'ukw'
  westcentralus: 'wcus'
  'West Central US': 'wcus'
  westeurope: 'weu'
  'West Europe': 'weu'
  westindia: 'win'
  'West India': 'win'
  westus: 'wus'
  'West US': 'wus'
  westus2: 'wus2'
  'West US 2': 'wus2'
  westus3: 'wus3'
  'West US 3': 'wus3'
}
var locationCode = locationCodeMap[location]

var metadata = {
  longName: '{0}-${name}-${env}-${locationCode}'
  shortName: replace('{0}${name}${env}${locationCode}', '-', '')
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: format(metadata.longName, 'rg')
  location: location
}

var apps = [
  {
    name: 'MD2HTML'
    suffix: 'md2html'
    apim: {
      nv: {
        name: 'X_FUNCTIONS_KEY_MD2HTML'
        displayName: 'X_FUNCTIONS_KEY_MD2HTML'
        value: 'to_be_updated'
      }
      api: {
        name: 'MD2HTML'
        path: 'md2html'
        subscriptionRequired: true
        format: 'openapi-link'
        value: 'https://raw.githubusercontent.com/hackersground-kr/infrastructure/main/infra/apim-api-openapi-md2html.yaml'
        policy: {
          format: 'xml-link'
          value: 'https://raw.githubusercontent.com/hackersground-kr/infrastructure/main/infra/apim-policy-api-md2html.xml'
        }
        operations: [
          // {
          //   name: ''
          //   policy: {
          //     format: ''
          //     value: ''
          //   }
          // }
        ]
      }
    }
  }
  {
    name: 'SMS'
    suffix: 'sms'
    apim: {
      nv: {
        name: 'X_FUNCTIONS_KEY_SMS'
        displayName: 'X_FUNCTIONS_KEY_SMS'
        value: 'to_be_updated'
      }
      api: {
        name: 'SMS'
        path: 'sms'
        subscriptionRequired: true
        format: 'openapi-link'
        value: 'https://raw.githubusercontent.com/hackersground-kr/infrastructure/main/infra/apim-api-openapi-sms.yaml'
        policy: {
          format: 'xml-link'
          value: 'https://raw.githubusercontent.com/hackersground-kr/infrastructure/main/infra/apim-policy-api-sms.xml'
        }
        operations: [
          // {
          //   name: ''
          //   policy: {
          //     format: ''
          //     value: ''
          //   }
          // }
        ]
      }
    }
  }
  {
    name: 'MMS'
    suffix: 'mms'
    apim: {
      nv: {
        name: 'X_FUNCTIONS_KEY_MMS'
        displayName: 'X_FUNCTIONS_KEY_MMS'
        value: 'to_be_updated'
      }
      api: {
        name: 'MMS'
        path: 'mms'
        subscriptionRequired: true
        format: 'openapi-link'
        value: 'https://raw.githubusercontent.com/hackersground-kr/infrastructure/main/infra/apim-api-openapi-mms.yaml'
        policy: {
          format: 'xml-link'
          value: 'https://raw.githubusercontent.com/hackersground-kr/infrastructure/main/infra/apim-policy-api-mms.xml'
        }
        operations: [
          // {
          //   name: ''
          //   policy: {
          //     format: ''
          //     value: ''
          //   }
          // }
        ]
      }
    }
  }
]

module apim './provision-apiManagement.bicep' = {
  name: 'Provision_ApiManagement'
  scope: rg
  params: {
    name: name
    location: location
    env: env
    apiMgmtPublisherEmail: apiManagementPublisherEmail
    apiMgmtPublisherName: apiManagementPublisherName
    apiMgmtPolicyFormat: 'xml-link'
    apiMgmtPolicyValue: 'https://raw.githubusercontent.com/hackersground-kr/infrastructure/main/infra/apim-policy-global.xml'
  }
}

module fncapps './provision-functionApp.bicep' = [for (app, i) in apps: {
  name: 'Provision_FunctionApp_${app.suffix}'
  scope: rg
  dependsOn: [
    apim
  ]
  params: {
    name: name
    location: location
    suffix: app.suffix
    env: env
  }
}]

module apis './provision-apiManagementApi.bicep' = [for (app, i) in apps: {
  name: 'ApiManagementApi_${app.suffix}'
  scope: rg
  dependsOn: [
    apim
    fncapps
  ]
  params: {
    name: name
    location: location
    env: env
    apiMgmtNVName: app.apim.nv.name
    apiMgmtNVDisplayName: app.apim.nv.displayName
    apiMgmtNVValue: app.apim.nv.value
    apiMgmtApiName: app.apim.api.name
    apiMgmtApiDisplayName: app.apim.api.name
    apiMgmtApiDescription: app.apim.api.name
    apiMgmtApiServiceUrl: 'https://fncapp-${name}-${app.suffix}-${env}-${locationCode}.azurewebsites.net/api'
    apiMgmtApiPath: app.apim.api.path
    apiMgmtApiSubscriptionRequired: app.apim.api.subscriptionRequired
    apiMgmtApiFormat: app.apim.api.format
    apiMgmtApiValue: app.apim.api.value
    apiMgmtApiPolicyFormat: app.apim.api.policy.format
    apiMgmtApiPolicyValue: app.apim.api.policy.value
    apiMgmtApiOperations: app.apim.api.operations
  }
}]
