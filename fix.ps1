# Função para verificar se o adaptador é sem fio
function IsWirelessAdapter($adapter) {
    $wirelessMediaTypes = 'Native 802.11', 'Wireless WAN', 'Wi-Fi Direct'  # Adicione mais tipos de mídia sem fio conforme necessário
    return $wirelessMediaTypes -contains $adapter.PhysicalMediaType
}

# Verifica se o script está sendo executado como administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "⚠️ Por favor, execute este script como administrador." -ForegroundColor Yellow
    $host.UI.PromptForChoice("Pressione uma tecla", "Pressione ENTER para fechar ou ESC para continuar", ("Enter", "Esc"), 1)
    Exit
}

Function Wait-KeyPress {
    do {
        $choice = $host.UI.PromptForChoice("Pressione uma tecla", "Pressione ENTER para fechar a janela ou ESC para continuar", ("Enter", "Esc"), 1)
        if ($choice -eq 1) {
            # Fecha a janela
            Exit
        }
    } while ($choice -ne 0)  # Repete até que o usuário pressione ENTER
}

Write-Host "`n`n===================== Iniciando Configurações =====================`n" -ForegroundColor Cyan

Write-Host "🔍 Verificando lista de adaptadores de rede sem fio..." -ForegroundColor Yellow
$adapters = Get-NetAdapter -Name *
$wirelessAdapters = $adapters | Where-Object { IsWirelessAdapter $_ }

if ($wirelessAdapters.Count -eq 0) {
    Write-Host "❌ Nenhum adaptador de rede sem fio encontrado" -ForegroundColor Red
    Wait-KeyPress
    Exit
}

foreach ($adapter in $wirelessAdapters) {
    Write-Host "`n🌐 Processando o adaptador de rede: $($adapter.Name)" -ForegroundColor Yellow

    Write-Host "   Configurando DNS para usar DHCP..."
    try {
        Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ResetServerAddresses
        Write-Host "   ✅ DNS configurado para usar DHCP" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Falha ao configurar DNS para usar DHCP. Erro: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "   Configurando DNS para a Cloudflare..."
    try {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("1.1.1.1","1.0.0.1","2606:4700:4700::1111","2606:4700:4700::1001")
        Write-Host "   ✅ Configurações de DNS atualizadas para a Cloudflare" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Falha ao configurar DNS para a Cloudflare. Erro: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n🗑️ Limpando todos os caches de DNS..." -ForegroundColor Cyan
try {
    $null = ipconfig /flushdns 2>&1
    Clear-DnsClientCache
    Write-Host "✅ Cache de DNS limpo" -ForegroundColor Green
} catch {
    Write-Host "❌ Falha ao limpar o cache de DNS. Erro: $($_.Exception.Message)" -ForegroundColor Red
}

# Aguarda o usuário digitar ENTER ou ESC
Write-Host "`n===================== Fim das Configurações =====================`n" -ForegroundColor Cyan
Wait-KeyPress
