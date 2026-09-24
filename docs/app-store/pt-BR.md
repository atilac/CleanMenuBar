# App Store — pt-BR

**Versão 0.1.3** — a mesma numeração do release no GitHub, de propósito: um
número, um binário, um conjunto de mudanças, onde quer que a pessoa encontre o app.

Em revisão. Os limites de caracteres são da Apple e são rígidos.

## Nome (30)

CleanMenuBar

## Subtítulo (30)

Organize sua barra de menus

## Palavras-chave (100)

> "bartender" removido: é marca registrada da Surtees Studios, e a Apple rejeita
> de forma inconsistente. Trocar tráfego incerto por risco concreto de rejeição
> no primeiro envio não compensa — dá para reavaliar num update.
>
> Palavras do nome e do subtítulo não entram: a Apple já indexa os dois.

esconder,ocultar,ícones,menubar,status,limpar,arrumar,produtividade,notch,atalho,minimalista

## Texto promocional (170)

> Único campo alterável sem reenviar o app. Reescrito para não repetir o
> subtítulo, que já diz "Organize sua barra de menus".

Esconda os ícones que você não usa e revele quando precisar. Sem permissões, sem coleta de dados, sem rede. Código aberto sob Licença MIT.

## Descrição (4000)

Sua barra de menus tem ícones demais? O CleanMenuBar esconde os que você não quer ver e revela quando você precisa.

COMO FUNCIONA

Dois itens aparecem na sua barra: um separador fino "|" e uma seta ">".

Segure ⌘ e arraste os ícones que quer esconder para a esquerda do separador "|". O que ficar à direita dele permanece sempre visível. Clique na seta ">" para recolher ou "<" para expandir — ou pressione ⌃⌥⌘C de qualquer lugar.

Depois de organizar tudo, ative "Ocultar os separadores" nos ajustes e só a seta continua na tela.

As posições sobrevivem a reinícios. O macOS lembra onde cada ícone ficou.

RECURSOS

• Esconda e revele com um clique, atalho global ou apenas passando o cursor
• Seção sempre oculta, para ícones que você nunca quer ver
• Recolhimento automático após 5, 10, 15, 30 ou 60 segundos
• Restauração do último estado ao abrir
• Abertura automática ao iniciar sessão
• Nove idiomas

SEM PERMISSÕES

O CleanMenuBar não pede nenhuma permissão especial. Não precisa de Acessibilidade nem de Gravação de Tela — incomum para uma ferramenta de barra de menus, e possível porque o atalho global usa uma API que dispensa essas permissões e o app nunca lê a tela.

Ele também não tem permissão de rede. Não conseguiria transmitir nada nem se o código tentasse. Nada é lido fora do próprio contêiner isolado.

EXIGE O macOS 27

O macOS 27 reconstruiu a barra de menus como uma única janela, e a técnica que alguns apps usam deixou de funcionar. O CleanMenuBar foi criado e medido diretamente no macOS 27, um dia após o seu lançamento público.

Versões anteriores do macOS não são compatíveis — e não precisam ser: nelas a técnica antiga ainda funciona.

Como o macOS 27 não roda em Macs Intel, o CleanMenuBar exige Apple Silicon.

CÓDIGO ABERTO

O código-fonte completo está publicado sob Licença MIT, incluindo o arquivo que declara exatamente o que o app tem permissão de fazer. Você não precisa acreditar em nada acima — pode verificar.

github.com/atilac/CleanMenuBar

AGRADECIMENTOS

O CleanMenuBar se apoia no Hidden Bar, da Dwarves Foundation, usado sob Licença MIT. Seus menus, ajustes e textos vieram de lá. Obrigado a todos que o mantiveram vivo ao longo de seis anos.

## Novidades desta versão

Primeira versão pública do CleanMenuBar.
