# forja

Script em bash para sintetizar e gravar FPGAs usando só ferramentas open source:

```
yosys → nextpnr → gowin_pack / icepack / ecppack → openFPGALoader
```

Você entra na pasta do projeto, roda `forja run` e ele sintetiza e grava na placa.

## Instalação

```bash
./install.sh          # cria o link ~/.local/bin/forja
forja doctor          # confere quais ferramentas estão instaladas
```

### Ferramentas: OSS CAD Suite (recomendado)

O [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build/releases) é um pacote pré-compilado da YosysHQ. Ele traz yosys, nextpnr (himbaechel, ice40, ecp5), gowin_pack, icepack, ecppack, openFPGALoader, iverilog e gtkwave, com as versões compatíveis entre si.

```bash
# baixe oss-cad-suite-linux-x64-<data>.tgz da página de releases e:
tar xzf oss-cad-suite-linux-x64-*.tgz -C ~/.local
echo 'export PATH="$HOME/.local/oss-cad-suite/bin:$PATH"' >> ~/.zshrc
```

Para atualizar, apague `~/.local/oss-cad-suite` e extraia uma versão nova.

> Pelo AUR, o `nextpnr-git` costuma quebrar na compilação: o ECP5 exige um prjtrellis mais novo que o do repositório oficial. Os pacotes `nextpnr-*-nightly` não incluem o backend Gowin (himbaechel).

Autocompletar no zsh: adicione ao `~/.zshrc`, antes do `compinit`:

```zsh
fpath=(~/Arquivos/forja/completions $fpath)
```

## Uso

```bash
forja synth  [pasta]   # sintetiza e gera o bitstream
forja load   [pasta]   # grava na placa o bitstream já gerado
forja run    [pasta]   # sintetiza (se algo mudou) e grava
forja sim    [pasta]   # simula com iverilog e abre o GTKWave
forja clean  [pasta]   # apaga build/
forja detect           # detecta a placa conectada
forja boards           # lista as placas suportadas
forja init -b <placa>  # cria forja.conf na pasta
forja doctor           # verifica as ferramentas
```

Se a pasta não for informada, ele usa a atual.

| Opção | Efeito |
|---|---|
| `-b, --board <placa>` | placa alvo |
| `-t, --top <módulo>` | módulo top (padrão: `top`) |
| `-p, --persistent` | grava na flash (permanente) em vez da SRAM |
| `-f, --force` | ressintetiza mesmo sem mudanças |
| `-v, --verbose` | mostra a saída completa das ferramentas |
| `-n, --no-wave` | (`sim`) não abre o GTKWave |

## Estrutura de um projeto

```
meu_projeto/
├── forja.conf          ← opcional: BOARD=, TOP=, CONSTRAINTS=
├── top.v               ← fontes .v/.sv na raiz ou em src/
├── outro_modulo.v
├── constraints.cst     ← pinagem (.cst Gowin, .pcf iCE40, .lpf ECP5)
├── sim/top_tb.v        ← testbench (<top>_tb.v)
└── build/<placa>/      ← gerado: bitstream e logs de cada etapa
```

- **Fontes:** o forja pega todos os `*.v` e `*.sv` da raiz e de `src/`, exceto os `*_tb.v`.
- **Pinagem:** procura, nesta ordem, o `CONSTRAINTS=` do `forja.conf`, depois `<placa>.<ext>`, depois `constraints.<ext>`, depois o único `*.<ext>` da pasta e, por último, a **pinagem padrão da placa** (`boards/<placa>.<ext>`, quando existe). Assim um projeto pode ter `tangnano20k.cst` e `icebreaker.pcf` lado a lado, ou não ter pinagem nenhuma e usar a da placa.
- **Cache:** a síntese só é refeita quando o conteúdo das fontes, da pinagem, da placa ou do top muda.
- **Logs:** cada etapa grava em `build/<placa>/<etapa>.log`. Se der erro, aparecem só as linhas relevantes.
- **Simulação:** o `vvp` roda com a pasta do projeto como diretório de trabalho, então use `$dumpfile("sim/dump.vcd")` ou `$dumpfile("dump.vcd")` no testbench.

Coloque `build/` no `.gitignore` dos seus projetos.

## Escolha da placa

A placa é escolhida nesta ordem de prioridade:

1. a opção `-b <placa>`;
2. o `BOARD=` do `forja.conf` do projeto;
3. o `BOARD=` de `~/.config/forja/config`, que é o padrão global.

```bash
mkdir -p ~/.config/forja && echo "BOARD=tangnano20k" > ~/.config/forja/config
```

## Placas

| Placa | Família | Status |
|---|---|---|
| `tangnano20k` | Gowin GW2AR-18C | perfil principal |
| `tangnano9k` | Gowin GW1NR-9C | |
| `icebreaker` | Lattice iCE40UP5K | |
| `ulx3s-85f` | Lattice ECP5 85F | |
| `de0cv` | Intel/Altera Cyclone V (5CEBA4) | open source (**Mistral**, experimental); só SRAM |

Para adicionar uma placa, copie `boards/_modelo.sh.txt` para `boards/<nome>.sh` ou para `~/.config/forja/boards/<nome>.sh` e preencha os campos. O nome usado pelo openFPGALoader aparece em `openFPGALoader --list-boards`. Se quiser uma pinagem padrão para a placa, coloque `<nome>.<ext>` (por exemplo, `<nome>.cst`) ao lado do perfil.

Famílias suportadas: **gowin**, **ice40**, **ecp5** e **mistral**, todas open source. Xilinx (openXC7) e Intel MAX 10 não são suportadas.

## DE0-CV com o Mistral (Cyclone V, open source)

O [Mistral](https://github.com/Ravenslofty/mistral) é um fluxo open source experimental para o Cyclone V: yosys (`synth_intel_alm`) → `nextpnr-mistral` → `.rbf`. Ele usa o mesmo formato `.qsf` de pinagem do Quartus. O `nextpnr-mistral` não vem no OSS CAD Suite e precisa ser compilado:

```bash
mkdir -p ~/.local/src && cd ~/.local/src
git clone https://github.com/YosysHQ/nextpnr.git
git clone https://github.com/Ravenslofty/mistral.git
# use a versão do Mistral que o CI do nextpnr usa (MISTRAL_REVISION em
# nextpnr/.github/workflows/arch_ci.yml); a mais nova pode não compilar
git -C mistral checkout ebfc0dd2cc7d6d2159b641a397c88554840e93c9
cd nextpnr && git submodule update --init --recursive
cmake -B build-mistral -G Ninja -DARCH=mistral -DMISTRAL_ROOT=$HOME/.local/src/mistral \
      -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$HOME/.local/nextpnr-mistral -DBUILD_GUI=OFF
choom -n 1000 -- ninja -C build-mistral -j1   # ver aviso abaixo
cmake --install build-mistral
```

> **Memória:** a compilação gera os bancos de dados de todos os chips Cyclone V, e cada um usa vários GB de RAM. Com `-j` alto, o sistema mata processos por falta de memória. Use `-j1`. O `choom -n 1000` faz o kernel matar a compilação, e não o resto do sistema, se a memória acabar.

O forja encontra o binário em `~/.local/nextpnr-mistral/bin` (ou em `$NEXTPNR_MISTRAL_DIR`) sem precisar mexer no PATH.

## Pinagem da DE0-CV

O arquivo [`boards/de0cv.qsf`](boards/de0cv.qsf), tirado do repositório [menotti/ld](https://github.com/menotti/ld) (licença MIT), traz clock (`CLOCK_50`), LEDs (`LEDR`), chaves (`SW`), botões (`KEY`), os 6 displays (`HEX0`–`HEX5`) e o VGA. Ele é a **pinagem padrão** da `de0cv`: se o projeto não tiver um `.qsf` próprio, o forja usa esse arquivo, como o `DE0_CV.qsf` compartilhado do Makefile do professor. Basta usar esses nomes nas portas do `top`; os sinais que o projeto não usa são ignorados. Para uma pinagem diferente, coloque um `constraints.qsf` na pasta do projeto.

A gravação usa o cabo `usb-blaster`; o openFPGALoader identifica o chip sozinho. A gravação permanente (`-p`) não é suportada: o forja ainda não grava a flash de configuração do Cyclone V.

> Nas placas iCE40, o openFPGALoader pode gravar na flash mesmo sem `-p`, dependendo da placa.
