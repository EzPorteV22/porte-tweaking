# Porte Tweaking - autocorreccion de codificacion (si el archivo se guardo sin BOM)
if ($PSCommandPath -and ('ó'.Length -gt 1)) {
    $porteTxt = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8)
    . ([scriptblock]::Create($porteTxt))
    return
}
# ===== PORTE TWEAKING =====
$Host.UI.RawUI.WindowTitle = 'Porte Tweaking'
function Show-Banner {
    try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
    Clear-Host
    $glyph = @{
        P = @('#####  ', '##  ## ', '#####  ', '##     ', '##     ', '##     ')
        O = @(' ####  ', '##  ## ', '##  ## ', '##  ## ', '##  ## ', ' ####  ')
        R = @('#####  ', '##  ## ', '#####  ', '## ##  ', '##  ## ', '##  ## ')
        T = @('###### ', '  ##   ', '  ##   ', '  ##   ', '  ##   ', '  ##   ')
        E = @('###### ', '##     ', '#####  ', '##     ', '##     ', '###### ')
    }
    $blk = [string][char]0x2588
    $cols = 'White', 'White', 'Gray', 'Gray', 'DarkGray', 'DarkGray'
    Write-Host ''
    for ($r = 0; $r -lt 6; $r++) {
        $line = '   '
        foreach ($ch in 'P', 'O', 'R', 'T', 'E') {
            foreach ($c in $glyph[$ch][$r].ToCharArray()) { if ($c -eq '#') { $line += $blk + $blk } else { $line += '  ' } }
            $line += '  '
        }
        Write-Host $line -ForegroundColor $cols[$r]
    }
    Write-Host "`n                         T W E A K I N G`n" -ForegroundColor DarkGray
    $full = [char]0x2588; $empty = [char]0x2591; $n = 44
    for ($p = 0; $p -le 100; $p += 2) {
        $f = [int]($n * $p / 100)
        Write-Host ("`r   Cargando  " + ([string]$full * $f) + ([string]$empty * ($n - $f)) + "  $p%") -NoNewline -ForegroundColor Gray
        Start-Sleep -Milliseconds 25
    }
    Write-Host ''
}
Show-Banner

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)


Add-Type -ReferencedAssemblies PresentationCore,PresentationFramework,WindowsBase,System.Xaml -TypeDefinition @"
using System;
using System.Windows;
using System.Windows.Media;
public class ParticleField : FrameworkElement {
    double[] X, Y, VX, VY, R; int N; Random rnd = new Random(7);
    Pen[] pens = new Pen[10]; Pen[] soft = new Pen[10]; Brush glow; Brush glowSoft; Brush core; Brush coreSoft; bool dark = true;
    public System.Collections.Generic.List<FrameworkElement> Targets = new System.Collections.Generic.List<FrameworkElement>();
    public FrameworkElement ClipTo;
    public ParticleField(int n) {
        N = n; X = new double[n]; Y = new double[n]; VX = new double[n]; VY = new double[n]; R = new double[n];
        for (int i = 0; i < n; i++) {
            X[i] = rnd.NextDouble(); Y[i] = rnd.NextDouble();
            double a = rnd.NextDouble() * 6.2832, s = 0.00018 + rnd.NextDouble() * 0.0004;
            VX[i] = Math.Cos(a) * s; VY[i] = Math.Sin(a) * s; R[i] = 1.3 + rnd.NextDouble() * 2.4;
        }
        IsHitTestVisible = false; Build();
        CompositionTarget.Rendering += delegate { Step(); InvalidateVisual(); };
    }
    public bool Dark { get { return dark; } set { dark = value; Build(); } }
    void Build() {
        Color c = dark ? Colors.White : Colors.Black;
        for (int i = 0; i < pens.Length; i++) {
            Pen p = new Pen(new SolidColorBrush(Color.FromArgb((byte)(8 + i * 15), c.R, c.G, c.B)), 1); p.Freeze(); pens[i] = p;
            Pen q = new Pen(new SolidColorBrush(Color.FromArgb((byte)(3 + i * 4), c.R, c.G, c.B)), 5); q.Freeze(); soft[i] = q;
        }
        RadialGradientBrush g = new RadialGradientBrush();
        g.GradientStops.Add(new GradientStop(Color.FromArgb(110, c.R, c.G, c.B), 0));
        g.GradientStops.Add(new GradientStop(Color.FromArgb(0, c.R, c.G, c.B), 1)); g.Freeze(); glow = g;
        RadialGradientBrush gs = new RadialGradientBrush();
        gs.GradientStops.Add(new GradientStop(Color.FromArgb(60, c.R, c.G, c.B), 0));
        gs.GradientStops.Add(new GradientStop(Color.FromArgb(0, c.R, c.G, c.B), 1)); gs.Freeze(); glowSoft = gs;
        SolidColorBrush k = new SolidColorBrush(Color.FromArgb(235, c.R, c.G, c.B)); k.Freeze(); core = k;
        RadialGradientBrush cs = new RadialGradientBrush();
        cs.GradientStops.Add(new GradientStop(Color.FromArgb(70, c.R, c.G, c.B), 0));
        cs.GradientStops.Add(new GradientStop(Color.FromArgb(0, c.R, c.G, c.B), 1)); cs.Freeze(); coreSoft = cs;
    }
    void Step() {
        for (int i = 0; i < N; i++) {
            X[i] += VX[i]; Y[i] += VY[i];
            if (X[i] < 0 || X[i] > 1) VX[i] = -VX[i];
            if (Y[i] < 0 || Y[i] > 1) VY[i] = -VY[i];
        }
    }
    void DrawLayer(DrawingContext dc, double w, double h, bool blur) {
        double md = 170;
        for (int i = 0; i < N; i++) for (int j = i + 1; j < N; j++) {
            double dx = (X[i] - X[j]) * w, dy = (Y[i] - Y[j]) * h, d2 = dx * dx + dy * dy;
            if (d2 < md * md) {
                int k = (int)((1 - Math.Sqrt(d2) / md) * 9.99);
                dc.DrawLine(blur ? soft[k] : pens[k], new Point(X[i] * w, Y[i] * h), new Point(X[j] * w, Y[j] * h));
            }
        }
        for (int i = 0; i < N; i++) {
            Point p = new Point(X[i] * w, Y[i] * h);
            if (blur) {
                dc.DrawEllipse(glowSoft, null, p, R[i] * 12, R[i] * 12);
                dc.DrawEllipse(coreSoft, null, p, R[i] * 2.8, R[i] * 2.8);
            } else {
                dc.DrawEllipse(glow, null, p, R[i] * 7, R[i] * 7);
                dc.DrawEllipse(core, null, p, R[i], R[i]);
            }
        }
    }
    protected override void OnRender(DrawingContext dc) {
        double w = ActualWidth, h = ActualHeight; if (w < 2) return;
        DrawLayer(dc, w, h, false);
    }
}
public static class Stress {
    static volatile bool stop = false;
    public static void Start(int n) {
        stop = false;
        for (int i = 0; i < n; i++) {
            System.Threading.Thread t = new System.Threading.Thread(delegate() { double x = 1.0; while (!stop) { x = Math.Sqrt(x + 1.0) * 1.0000001; } });
            t.IsBackground = true; t.Priority = System.Threading.ThreadPriority.BelowNormal; t.Start();
        }
    }
    public static void Stop() { stop = true; }
}
public static class TimerRes {
    [System.Runtime.InteropServices.DllImport("ntdll.dll")] static extern int NtQueryTimerResolution(out uint min, out uint max, out uint cur);
    public static string Get() {
        uint a, b, c; NtQueryTimerResolution(out a, out b, out c);
        System.Globalization.CultureInfo ci = System.Globalization.CultureInfo.InvariantCulture;
        return (a / 10000.0).ToString("0.000", ci) + "|" + (b / 10000.0).ToString("0.000", ci) + "|" + (c / 10000.0).ToString("0.000", ci);
    }
}
"@

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
 Title="Porte Tweaking" Width="1440" Height="900" WindowStartupLocation="CenterScreen" WindowStyle="None"
 AllowsTransparency="True" Background="Transparent" ResizeMode="CanMinimize" FontFamily="Segoe UI Variable Display, Segoe UI">
<Window.Resources>
 <Style x:Key="Switch" TargetType="CheckBox"><Setter Property="Cursor" Value="Hand"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="CheckBox">
  <Border x:Name="Track" Width="46" Height="26" CornerRadius="13" Background="{DynamicResource TrackOff}" BorderBrush="{DynamicResource CardBorder}" BorderThickness="1">
   <Ellipse x:Name="Thumb" Width="18" Height="18" Fill="{DynamicResource MutedBrush}" HorizontalAlignment="Left" Margin="3,0,0,0"/></Border>
  <ControlTemplate.Triggers><Trigger Property="IsChecked" Value="True">
   <Setter TargetName="Track" Property="Background" Value="{DynamicResource TrackOn}"/>
   <Setter TargetName="Thumb" Property="Fill" Value="{DynamicResource ThumbOn}"/>
   <Setter TargetName="Thumb" Property="HorizontalAlignment" Value="Right"/>
   <Setter TargetName="Thumb" Property="Margin" Value="0,0,3,0"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
 <Style x:Key="Pill" TargetType="Button"><Setter Property="Cursor" Value="Hand"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
  <Border x:Name="B" CornerRadius="11" Background="{DynamicResource BtnBg}" Padding="18,9">
   <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" TextElement.Foreground="{DynamicResource BtnFg}" TextElement.FontWeight="SemiBold" TextElement.FontSize="13"/></Border>
  <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="B" Property="Opacity" Value="0.82"/></Trigger>
  <Trigger Property="IsPressed" Value="True"><Setter TargetName="B" Property="Opacity" Value="0.65"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
 <Style x:Key="Ghost" TargetType="Button"><Setter Property="Cursor" Value="Hand"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
  <Border x:Name="B" CornerRadius="11" Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource CardBorder}" BorderThickness="1" Padding="18,9">
   <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" TextElement.Foreground="{DynamicResource TextBrush}" TextElement.FontWeight="SemiBold" TextElement.FontSize="13"/></Border>
  <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="B" Property="Background" Value="{DynamicResource HoverBrush}"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
 <Style x:Key="WinBtn" TargetType="Button"><Setter Property="Cursor" Value="Hand"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
  <Border x:Name="B" Width="42" Height="30" CornerRadius="8" Background="Transparent">
   <TextBlock Text="{TemplateBinding Content}" FontFamily="Segoe MDL2 Assets" FontSize="11" Foreground="{DynamicResource MutedBrush}" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
  <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="B" Property="Background" Value="{DynamicResource HoverBrush}"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
 <Style x:Key="Nav" TargetType="RadioButton"><Setter Property="Cursor" Value="Hand"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="RadioButton">
  <Border x:Name="B" CornerRadius="12" Padding="14,8" Margin="0,0,0,3" Background="Transparent" BorderThickness="1" BorderBrush="Transparent">
   <StackPanel Orientation="Horizontal">
    <TextBlock x:Name="I" Text="{TemplateBinding Tag}" FontFamily="Segoe MDL2 Assets" FontSize="16" Foreground="{DynamicResource MutedBrush}" VerticalAlignment="Center" Width="28"/>
    <TextBlock x:Name="T" Text="{TemplateBinding Content}" FontSize="14" Foreground="{DynamicResource MutedBrush}" VerticalAlignment="Center"/></StackPanel></Border>
  <ControlTemplate.Triggers>
   <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="B" Property="Background" Value="{DynamicResource HoverBrush}"/></Trigger>
   <Trigger Property="IsChecked" Value="True"><Setter TargetName="B" Property="Background" Value="{DynamicResource CardBrush}"/><Setter TargetName="B" Property="BorderBrush" Value="{DynamicResource CardBorder}"/>
    <Setter TargetName="I" Property="Foreground" Value="{DynamicResource TextBrush}"/><Setter TargetName="T" Property="Foreground" Value="{DynamicResource TextBrush}"/></Trigger>
  </ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
</Window.Resources>
<Border x:Name="Root" CornerRadius="20" Background="{DynamicResource BgBrush}" BorderBrush="{DynamicResource CardBorder}" BorderThickness="1" ClipToBounds="True">
<Grid>
 <Ellipse Width="720" Height="720" Fill="{DynamicResource GlowBrush}" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,-340,-220,0" IsHitTestVisible="False"><Ellipse.Effect><BlurEffect Radius="130"/></Ellipse.Effect></Ellipse>
 <Ellipse Width="460" Height="460" Fill="{DynamicResource GlowBrush}" HorizontalAlignment="Left" VerticalAlignment="Bottom" Margin="120,0,0,-260" IsHitTestVisible="False"><Ellipse.Effect><BlurEffect Radius="110"/></Ellipse.Effect></Ellipse>
 <Grid>
  <Grid.ColumnDefinitions><ColumnDefinition Width="276"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
  <Border Grid.Column="0" Margin="12" Background="{DynamicResource SideBrush}" CornerRadius="18" BorderBrush="{DynamicResource CardBorder}" BorderThickness="1">
   <DockPanel Margin="22,30,22,22">
    <StackPanel DockPanel.Dock="Bottom">
     <Border CornerRadius="14" Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource CardBorder}" BorderThickness="1" Padding="16,12">
      <DockPanel><CheckBox x:Name="ThemeSwitch" DockPanel.Dock="Right" Style="{StaticResource Switch}" IsChecked="True" VerticalAlignment="Center"/>
       <StackPanel><TextBlock x:Name="ThemeLbl" Text="Modo oscuro" FontSize="13" FontWeight="SemiBold" Foreground="{DynamicResource TextBrush}"/>
       <TextBlock Text="Blanco y negro" FontSize="11" Foreground="{DynamicResource MutedBrush}"/></StackPanel></DockPanel></Border>
     <TextBlock Text="Porte Tweaking  v1.0" FontSize="11" Foreground="{DynamicResource MutedBrush}" HorizontalAlignment="Center" Margin="0,14,0,0"/>
    </StackPanel>
    <StackPanel>
     <TextBlock Text="PORTE" FontSize="38" FontWeight="Black" Foreground="{DynamicResource AccentBrush}" Margin="8,0,0,0"/>
     <TextBlock Text="T W E A K I N G" FontSize="11" Foreground="{DynamicResource MutedBrush}" Margin="10,0,0,24"/>
     <Rectangle Height="1" Fill="{DynamicResource LineBrush}" Margin="0,0,0,22"/>
     <StackPanel x:Name="NavPanel"/>
    </StackPanel>
   </DockPanel>
  </Border>
  <Grid Grid.Column="1">
   <Grid.RowDefinitions><RowDefinition Height="52"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
   <Grid x:Name="TitleBar" Background="Transparent">
    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,10,14,0" VerticalAlignment="Top">
     <Button x:Name="BtnMin" Style="{StaticResource WinBtn}" Content="&#xE921;"/><Button x:Name="BtnClose" Style="{StaticResource WinBtn}" Content="&#xE8BB;"/></StackPanel></Grid>
   <StackPanel Grid.Row="1" Margin="38,4,38,18">
    <TextBlock x:Name="PageTitle" FontSize="32" FontWeight="Bold" Foreground="{DynamicResource TextBrush}"/>
    <TextBlock x:Name="PageSub" FontSize="13" Foreground="{DynamicResource MutedBrush}" Margin="0,4,0,16"/>
    <Rectangle Height="2" Fill="{DynamicResource LineBrush}" RadiusX="1" RadiusY="1"/></StackPanel>
   <ScrollViewer x:Name="Scroller" Grid.Row="2" VerticalScrollBarVisibility="Hidden" Margin="38,0,26,0"><Grid>
    <Grid x:Name="PageHost"/>
   </Grid></ScrollViewer>
   <Border x:Name="Footer" Grid.Row="3" Margin="38,10,38,24" CornerRadius="16" Padding="20,14" Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource CardBorder}" BorderThickness="1">
    <DockPanel><StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
      <Button x:Name="BtnRevert" Style="{StaticResource Ghost}" Content="Revertir todo" Margin="0,0,10,0"/>
      <Button x:Name="BtnAll" Style="{StaticResource Ghost}" Content="Seleccionar todo" Margin="0,0,10,0"/>
      <Button x:Name="BtnApply" Style="{StaticResource Pill}" Content="Aplicar tweaks"/></StackPanel>
     <TextBlock x:Name="Status" Text="Listo." FontSize="13" Foreground="{DynamicResource MutedBrush}" VerticalAlignment="Center"/></DockPanel></Border>
  </Grid>
 </Grid>
</Grid></Border></Window>
'@

$w = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
foreach ($n in 'ThemeSwitch','ThemeLbl','NavPanel','TitleBar','BtnMin','BtnClose','PageTitle','PageSub','PageHost','Scroller','Footer','BtnAll','BtnApply','BtnRevert','Status') { Set-Variable $n ($w.FindName($n)) }

# ---------- Temas ----------
function Br($h) { [Windows.Media.BrushConverter]::new().ConvertFromString($h) }
function Col($h) { [Windows.Media.Color][Windows.Media.ColorConverter]::ConvertFromString($h) }
function Gr($a,$b,$ang) {
    $g = [Windows.Media.LinearGradientBrush]::new((Col $a), (Col $b), [double]$ang)
    $g.psobject.BaseObject
}
function Line($c) {
    $g = [Windows.Media.LinearGradientBrush]::new()
    $g.StartPoint = [Windows.Point]::new(0, 0); $g.EndPoint = [Windows.Point]::new(1, 0)
    $g.GradientStops.Add([Windows.Media.GradientStop]::new((Col '#00FFFFFF'), 0.0))
    $g.GradientStops.Add([Windows.Media.GradientStop]::new((Col $c), 0.5))
    $g.GradientStops.Add([Windows.Media.GradientStop]::new((Col '#00FFFFFF'), 1.0))
    $g.psobject.BaseObject
}
function Set-Res($k, $v) { $w.Resources[$k] = $v.psobject.BaseObject }
function Set-Theme($dark) {
    if ($script:field) { $script:field.Dark = [bool]$dark }
    $r = $w.Resources
    Set-Res 'BusyDim' (Br $(if ($dark) { '#A6000000' } else { '#A6FFFFFF' }))
    Set-Res 'BusyCard' (Br $(if ($dark) { '#F2141418' } else { '#F2FFFFFF' }))
    if ($dark) {
        Set-Res 'BgBrush' (Gr '#08080A' '#1A1A20' 135); Set-Res 'SideBrush' (Br '#F20C0C0F'); Set-Res 'CardBrush' (Br '#12FFFFFF'); Set-Res 'CardBorder' (Br '#22FFFFFF')
        Set-Res 'TextBrush' (Br '#F5F5F7'); Set-Res 'MutedBrush' (Br '#8E8E96'); Set-Res 'HoverBrush' (Br '#1CFFFFFF'); Set-Res 'TrackOff' (Br '#26FFFFFF')
        Set-Res 'TrackOn' (Br '#F2F2F2'); Set-Res 'ThumbOn' (Br '#08080A'); Set-Res 'BtnBg' (Gr '#FFFFFF' '#B4B4BC' 90); Set-Res 'BtnFg' (Br '#08080A')
        Set-Res 'AccentBrush' (Gr '#FFFFFF' '#6E6E78' 90); Set-Res 'GlowBrush' (Br '#30FFFFFF'); Set-Res 'LineBrush' (Line '#66FFFFFF')
        $ThemeLbl.Text = 'Modo oscuro'
    } else {
        Set-Res 'BgBrush' (Gr '#FFFFFF' '#E9E9EE' 135); Set-Res 'SideBrush' (Br '#F2F6F6F8'); Set-Res 'CardBrush' (Br '#09000000'); Set-Res 'CardBorder' (Br '#22000000')
        Set-Res 'TextBrush' (Br '#0A0A0C'); Set-Res 'MutedBrush' (Br '#6B6B73'); Set-Res 'HoverBrush' (Br '#12000000'); Set-Res 'TrackOff' (Br '#1F000000')
        Set-Res 'TrackOn' (Br '#0A0A0C'); Set-Res 'ThumbOn' (Br '#FFFFFF'); Set-Res 'BtnBg' (Gr '#26262B' '#000000' 90); Set-Res 'BtnFg' (Br '#FFFFFF')
        Set-Res 'AccentBrush' (Gr '#000000' '#7A7A82' 90); Set-Res 'GlowBrush' (Br '#26000000'); Set-Res 'LineBrush' (Line '#66000000')
        $ThemeLbl.Text = 'Modo claro'
    }
}
$script:field = New-Object ParticleField 70
$script:rootGrid = $w.FindName('Root').Child
$script:rootGrid.Children[2].Children.Insert(0, $script:field)
[Windows.Controls.Grid]::SetColumn($script:field, 1)
$script:field.ClipTo = $w.FindName('Scroller')
$script:rootGrid.Clip = [Windows.Media.RectangleGeometry]::new([Windows.Rect]::new(0, 0, 1438, 898), 19, 19)
Set-Theme $true
$ThemeSwitch.Add_Click({ Set-Theme ([bool]$ThemeSwitch.IsChecked) })

# ---------- Helpers UI ----------
function Say($t) {
    $Status.Text = $t
    if ($script:BusyDepth -gt 0 -and $script:BusySub -and $t) { $script:BusySub.Text = $t }
    $w.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Render)
    if ($t -and $t -ne $script:LastSay -and $t -notlike 'Prueba de estr*') { Write-Host ('[{0}] {1}' -f (Get-Date -Format 'HH:mm:ss'), $t) -ForegroundColor DarkGray; $script:LastSay = $t }
}
function Tx($t,$size,$key,$weight='Normal') {
    $x = New-Object Windows.Controls.TextBlock; $x.Text=$t; $x.FontSize=$size; $x.FontWeight=$weight; $x.TextWrapping='Wrap'
    $x.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, $key); $x
}
function New-Card($title,$desc,$ctrl,$tag='') {
    $b = New-Object Windows.Controls.Border; $b.CornerRadius=[Windows.CornerRadius]::new(16); $b.Margin=[Windows.Thickness]::new(0,0,12,12)
    $b.Padding=[Windows.Thickness]::new(20,16,20,16); $b.BorderThickness=[Windows.Thickness]::new(1); $b.MinHeight=84
    $b.SetResourceReference([Windows.Controls.Border]::BackgroundProperty,'CardBrush'); $b.SetResourceReference([Windows.Controls.Border]::BorderBrushProperty,'CardBorder')
    $g = New-Object Windows.Controls.DockPanel
    [Windows.Controls.DockPanel]::SetDock($ctrl,'Right'); $ctrl.VerticalAlignment='Center'; $ctrl.Margin=[Windows.Thickness]::new(16,0,0,0); $g.Children.Add($ctrl) | Out-Null
    $sp = New-Object Windows.Controls.StackPanel; $sp.VerticalAlignment='Center'
    $sp.Children.Add((Tx $title 14.5 'TextBrush' 'SemiBold')) | Out-Null
    $d = Tx $desc 12 'MutedBrush'; $d.Margin=[Windows.Thickness]::new(0,4,0,0); $sp.Children.Add($d) | Out-Null
    if ($tag) { $g2 = Tx $tag 11 'TextBrush' 'SemiBold'; $g2.Margin=[Windows.Thickness]::new(0,7,0,0); $g2.Opacity=0.7; $sp.Children.Add($g2) | Out-Null }
    $g.Children.Add($sp) | Out-Null; $b.Child = $g; $b
}
function Set-Reg($p,$n,$v,$t='DWord') {
    $old = $null; try { $old = (Get-ItemProperty -Path $p -Name $n -ErrorAction Stop).$n } catch {}
    $script:Undo += [pscustomobject]@{ Kind='reg'; Path=$p; Name=$n; Old=$old; Type=$t }
    if (!(Test-Path $p)) { New-Item $p -Force | Out-Null }
    New-ItemProperty $p -Name $n -Value $v -PropertyType $t -Force | Out-Null
}
function Pill($text,$style='Pill') { $b = New-Object Windows.Controls.Button; $b.Content=$text; $b.Style=$w.FindResource($style); $b }

# =====================================================================
#   PORTE TWEAKING v2  -  medir, cambiar UNA cosa, medir, revertir
# =====================================================================
$script:Dir = "$env:LOCALAPPDATA\PorteTweaking"
New-Item -ItemType Directory -Force $script:Dir | Out-Null
$script:UndoFile = "$script:Dir\undo.json"; $script:BenchFile = "$script:Dir\bench.json"
$script:BaseFile = "$script:Dir\baseline.json"; $script:JournalFile = "$script:Dir\journal.txt"
$script:Undo = @(); $script:PorteGuid = $null; $script:Cur = @{}; $script:CurPage = 'home'; $script:checks = @(); $script:GameBox = $null
$script:Pages = [ordered]@{}
$script:MM = @{
  FT  = 'PresentMon/CapFrameX: FPS promedio, 1% low, 0.1% low y frametime (pestaña Benchmark)'
  LAT = 'Pestaña Latencia: DPC/ISR por núcleo y jitter del timer. Para input real: cámara de alta velocidad o LDAT'
  NET = 'Pestaña Red: ping, jitter y pérdida (local vs internet)'
  TMP = 'Pestaña Temperaturas: prueba de estrés, reloj sostenido y temperatura'
  DSK = 'Pestaña Almacenamiento: salud, temperatura y actividad de disco'
  SEC = 'Benchmark antes/después y tu criterio sobre la seguridad'
  NA  = 'No aplica'
}

# ---------- Mantener la ventana viva durante tareas largas ----------
function Pump { $w.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background) }
function Wait-Ui([int]$ms) { $sw = [Diagnostics.Stopwatch]::StartNew(); while ($sw.ElapsedMilliseconds -lt $ms) { Pump; Start-Sleep -Milliseconds 20 } }
function Use-Busy([string]$title, [scriptblock]$sb) { Show-Busy $title; try { & $sb } finally { Hide-Busy } }

# ---------- Controles base ----------
function Nil($t = '') { Tx $t 12 'MutedBrush' }
function New-Card($title, $desc, $ctrl, $tag = '', $tagColor = $null, $tip = $null) {
    $b = New-Object Windows.Controls.Border; $b.CornerRadius = [Windows.CornerRadius]::new(16); $b.Margin = [Windows.Thickness]::new(0,0,12,12)
    $b.Padding = [Windows.Thickness]::new(20,16,20,16); $b.BorderThickness = [Windows.Thickness]::new(1); $b.MinHeight = 84
    $b.SetResourceReference([Windows.Controls.Border]::BackgroundProperty, 'CardBrush'); $b.SetResourceReference([Windows.Controls.Border]::BorderBrushProperty, 'CardBorder')
    if ($tip) { $b.ToolTip = $tip }
    $g = New-Object Windows.Controls.DockPanel
    [Windows.Controls.DockPanel]::SetDock($ctrl, 'Right'); $ctrl.VerticalAlignment = 'Center'; $ctrl.Margin = [Windows.Thickness]::new(16,0,0,0); $g.Children.Add($ctrl) | Out-Null
    $sp = New-Object Windows.Controls.StackPanel; $sp.VerticalAlignment = 'Center'
    $sp.Children.Add((Tx $title 14.5 'TextBrush' 'SemiBold')) | Out-Null
    if ($desc) { $d = Tx $desc 12 'MutedBrush'; $d.Margin = [Windows.Thickness]::new(0,4,0,0); $sp.Children.Add($d) | Out-Null }
    if ($tag) { $t2 = Tx $tag 11 'TextBrush' 'SemiBold'; $t2.Margin = [Windows.Thickness]::new(0,7,0,0); if ($tagColor) { $t2.Foreground = Br $tagColor } else { $t2.Opacity = 0.7 }; $sp.Children.Add($t2) | Out-Null }
    $g.Children.Add($sp) | Out-Null; $b.Child = $g; $script:field.Targets.Add($b); $b
}
function New-Diag($title, $desc, $ctrl) {
    $c = New-Card $title $desc $ctrl
    $o = Tx '' 12.5 'TextBrush'; $o.FontFamily = 'Consolas'; $o.Margin = [Windows.Thickness]::new(0,10,0,0); $o.Visibility = 'Collapsed'
    $c.Child.Children[1].Children.Add($o) | Out-Null
    @{ Card = $c; Out = $o }
}
function Show-Out($o, $text) { $o.Text = $text; $o.Visibility = 'Visible'; Say 'Listo.' }
function Add-Action($btn, $out, [scriptblock]$act, [string]$busy = 'Procesando') {
    $btn.Tag = @{ Out = $out; Act = $act; Busy = $busy }
    $btn.Add_Click({ param($s, $e)
        $t = $s.Tag; Say 'Trabajando...'
        if ($t.Busy) { Show-Busy $t.Busy }
        try { $r = & $t.Act; Show-Out $t.Out ([string]($r -join "`n")) } catch { Show-Out $t.Out ('Error: ' + $_.Exception.Message) } finally { if ($t.Busy) { Hide-Busy } }
    })
}
function Add-DiagCard($pageKey, $title, $desc, $btnText, [scriptblock]$act, $style = 'Pill') {
    $btn = Pill $btnText $style
    $d = New-Diag $title $desc $btn
    Add-Action $btn $d.Out $act $title
    $script:Pages[$pageKey].Panel.Children.Add($d.Card) | Out-Null
}
function Add-Info($pageKey, $title, $text, $tag = '', $color = $null) {
    $script:Pages[$pageKey].Panel.Children.Add((New-Card $title $text (Nil '') $tag $color)) | Out-Null
}

# ---------- Deshacer ----------
function Save-Undo {
    if (-not $script:Undo.Count) { return }
    $all = @(); if (Test-Path $script:UndoFile) { $all = @(Get-Content $script:UndoFile -Raw | ConvertFrom-Json) }
    foreach ($u in $script:Undo) {
        $k = "$($u.Kind)|$($u.Path)|$($u.Name)|$($u.Kw)"
        if ($all | Where-Object { "$($_.Kind)|$($_.Path)|$($_.Name)|$($_.Kw)" -eq $k }) { continue }
        $all += $u
    }
    ConvertTo-Json -InputObject @($all) -Depth 4 | Set-Content $script:UndoFile -Encoding UTF8
    $script:Undo = @()
}
function Restore-All {
    if (-not (Test-Path $script:UndoFile)) { Say 'No hay cambios para revertir.'; return }
    $all = @(Get-Content $script:UndoFile -Raw | ConvertFrom-Json); [array]::Reverse($all)
    foreach ($u in $all) {
        try {
            switch ($u.Kind) {
                'reg'     { if ($null -eq $u.Old) { Remove-ItemProperty -Path $u.Path -Name $u.Name -ErrorAction SilentlyContinue } else { $v = $u.Old; if ($u.Type -eq 'Binary') { $v = [byte[]]$u.Old }; New-ItemProperty -Path $u.Path -Name $u.Name -Value $v -PropertyType $u.Type -Force | Out-Null } }
                'plan'    { powercfg /setactive $u.Old | Out-Null; powercfg /delete $u.New | Out-Null }
                'task'    { Enable-ScheduledTask -TaskPath $u.Path -TaskName $u.Name | Out-Null }
                'hv'      { bcdedit /set hypervisorlaunchtype auto | Out-Null }
                'netpm'   { Set-NetAdapterPowerManagement -Name $u.Name -AllowComputerToTurnOffDevice $u.Old }
                'adv'     { Set-NetAdapterAdvancedProperty -Name $u.Name -RegistryKeyword $u.Kw -RegistryValue $u.Old }
            }
        } catch {}
    }
    Remove-Item $script:UndoFile -Force -ErrorAction SilentlyContinue
    $script:PorteGuid = $null
    Say 'Todo revertido. Algunos cambios necesitan reiniciar.'
}
function Get-PortePlan {
    if ($script:PorteGuid) { return $script:PorteGuid }
    $ex = @(powercfg /list | Where-Object { $_ -match 'Porte Tweaking' })
    if ($ex.Count) { $g = [regex]::Match($ex[0], '[0-9a-fA-F-]{36}').Value; powercfg /setactive $g | Out-Null; $script:PorteGuid = $g; return $g }
    $cur = [regex]::Match((powercfg /getactivescheme | Out-String), '[0-9a-fA-F-]{36}').Value
    $dup = [regex]::Match((powercfg -duplicatescheme $cur | Out-String), '[0-9a-fA-F-]{36}').Value
    powercfg /changename $dup 'Porte Tweaking' | Out-Null
    powercfg /setactive $dup | Out-Null
    $script:Undo += [pscustomobject]@{ Kind = 'plan'; Old = $cur; New = $dup }
    $script:PorteGuid = $dup; $dup
}
function Get-ActiveAdapter { Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1 }
function Set-AdvProp($kw, $val) {
    $ad = Get-ActiveAdapter; if (-not $ad) { throw 'No hay un adaptador de red activo.' }
    $p = Get-NetAdapterAdvancedProperty -Name $ad.Name -RegistryKeyword $kw -ErrorAction SilentlyContinue
    if (-not $p) { throw "El driver de $($ad.Name) no expone $kw." }
    $script:Undo += [pscustomobject]@{ Kind = 'adv'; Name = $ad.Name; Kw = $kw; Old = [string]$p.RegistryValue[0] }
    Set-NetAdapterAdvancedProperty -Name $ad.Name -RegistryKeyword $kw -RegistryValue $val
}

# ---------- Paginas ----------
function Go($k) {
    foreach ($p in $script:Pages.Values) { $p.Panel.Visibility = 'Collapsed' }
    $pg = $script:Pages[$k]; $pg.Panel.Visibility = 'Visible'
    $PageTitle.Text = $pg.Title; $PageSub.Text = $pg.Sub
    $Footer.Visibility = if ($pg.Footer) { 'Visible' } else { 'Collapsed' }
    $script:CurPage = $k
}
function New-Page($key, $icon, $nav, $title, $sub, $footer) {
    $panel = New-Object Windows.Controls.StackPanel; $panel.Visibility = 'Collapsed'; $panel.VerticalAlignment = 'Top'
    $grid = New-Object Windows.Controls.Primitives.UniformGrid; $grid.Columns = 2
    $PageHost.Children.Add($panel) | Out-Null
    $rb = New-Object Windows.Controls.RadioButton; $rb.Style = $w.FindResource('Nav'); $rb.Content = $nav; $rb.Tag = [string][char]$icon; $rb.GroupName = 'n'; $rb.Name = $key
    $rb.Add_Checked({ param($s, $e) Go $s.Name })
    $NavPanel.Children.Add($rb) | Out-Null
    $script:Pages[$key] = @{ Panel = $panel; Grid = $grid; Title = $title; Sub = $sub; Footer = $footer; Nav = $rb }
}

# ---------- Utilidades de lectura ----------
function Get-Reg($p, $n) { try { (Get-ItemProperty -Path $p -Name $n -ErrorAction Stop).$n } catch { $null } }
function Nz($x) { if ($null -eq $x) { 'no definido' } else { $x } }
function Fmt-Date($d) { if ($d) { ([datetime]$d).ToString('yyyy-MM-dd') } else { 's/d' } }
function Get-Smi {
    $exe = (Get-Command nvidia-smi -ErrorAction SilentlyContinue).Source
    if (-not $exe) { foreach ($p in "$env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe", "$env:windir\System32\nvidia-smi.exe") { if (Test-Path $p) { $exe = $p; break } } }
    $exe
}
function Get-GpuLive {
    $exe = Get-Smi; if (-not $exe) { return $null }
    $o = & $exe --query-gpu=name,driver_version,temperature.gpu,clocks.sm,clocks.max.sm,power.draw,power.limit,utilization.gpu,memory.used,memory.total,pstate --format=csv,noheader,nounits 2>$null
    if (-not $o) { return $null }
    $f = @(([string]($o | Select-Object -First 1)).Split(',') | ForEach-Object { $_.Trim() })
    '{0} | driver {1} | {2} °C | SM {3}/{4} MHz | {5}/{6} W | GPU {7}% | VRAM {8}/{9} MiB | {10}' -f $f
}
function Get-GpuThrottle {
    $exe = Get-Smi; if (-not $exe) { return $null }
    $q = & $exe -q -d PERFORMANCE 2>$null
    $act = @($q | Where-Object { $_ -match ':\s+Active' } | ForEach-Object { $_.Trim() })
    if ($act.Count) { $act } else { @('Sin limitaciones activas en este momento (medilo con el juego corriendo).') }
}
function Get-CpuTemp {
    $z = Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
    if ($z) { [math]::Round((($z | ForEach-Object { $_.CurrentTemperature / 10 - 273.15 }) | Measure-Object -Maximum).Maximum, 1) }
}
function Get-TimerInfo {
    $r = [TimerRes]::Get().Split('|')
    $l = @("Resolución del timer: actual $($r[2]) ms (rango del sistema $($r[1]) a $($r[0]) ms)")
    $bcd = (bcdedit /enum '{current}' 2>&1 | Out-String)
    foreach ($k in 'useplatformclock', 'useplatformtick', 'disabledynamictick') {
        $m = [regex]::Match($bcd, "$k\s+(\w+)")
        $l += "bcdedit $k : " + $(if ($m.Success) { $m.Groups[1].Value } else { 'no definido (valor por defecto de Windows)' })
    }
    $hp = @(Get-PnpDevice -FriendlyName '*High Precision Event Timer*' -ErrorAction SilentlyContinue)
    $l += 'Dispositivo HPET visible en Windows: ' + $(if ($hp.Count) { 'sí' } else { 'no' })
    $l += 'Lectura: si no hay useplatformclock definido, Windows usa su configuración por defecto y no hay un problema que justifique tocar HPET. Solo investigá si DPC/ISR muestra picos.'
    $l
}
function Get-DpcCores {
    $acc = @{}
    1..6 | ForEach-Object {
        Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '_Total' } | ForEach-Object {
            if (-not $acc.ContainsKey($_.Name)) { $acc[$_.Name] = @(0.0, 0.0, 0) }
            $acc[$_.Name][0] += [double]$_.PercentDPCTime; $acc[$_.Name][1] += [double]$_.PercentInterruptTime; $acc[$_.Name][2]++
        }
        Wait-Ui 700
    }
    if (-not $acc.Count) { return @('No se pudieron leer los contadores de DPC/ISR.') }
    $rows = $acc.GetEnumerator() | ForEach-Object { [pscustomobject]@{ Core = $_.Key; Dpc = $_.Value[0] / $_.Value[2]; Isr = $_.Value[1] / $_.Value[2] } } | Sort-Object { $_.Dpc + $_.Isr } -Descending
    $tot = ($rows | ForEach-Object { $_.Dpc + $_.Isr } | Measure-Object -Sum).Sum
    $out = @($rows | Select-Object -First 8 | ForEach-Object { '{0,-8} DPC {1,6:N2}%   ISR {2,6:N2}%' -f $_.Core, $_.Dpc, $_.Isr })
    $top = $rows | Select-Object -First 1
    if ($tot -gt 0.5 -and (($top.Dpc + $top.Isr) / $tot) -gt 0.6) { $out += 'Aviso: más del 60% de DPC/ISR se concentra en un solo núcleo. Revisá qué driver lo genera (captura WPR o LatencyMon).' }
    $out += 'Estos son promedios del sistema. Para saber QUÉ driver causa los picos (ndis.sys, dxgkrnl.sys, nvlddmkm.sys, amdkmdag, storport.sys, USB, audio, Bluetooth) hace falta una traza ETW: usá los botones de captura.'
    $out
}
function Test-Ping($target, $n = 30) {
    $p = New-Object Net.NetworkInformation.Ping; $rt = @(); $lost = 0
    for ($i = 0; $i -lt $n; $i++) {
        try { $r = $p.Send($target, 1000); if ($r.Status -eq 'Success') { $rt += [double]$r.RoundtripTime } else { $lost++ } } catch { $lost++ }
        Wait-Ui 120
    }
    if (-not $rt.Count) { return "$target : sin respuesta (pérdida 100%)" }
    $j = 0; if ($rt.Count -gt 1) { $d = for ($i = 1; $i -lt $rt.Count; $i++) { [math]::Abs($rt[$i] - $rt[$i-1]) }; $j = ($d | Measure-Object -Average).Average }
    'objetivo {0,-16} ping prom {1,5:N1} ms | mín {2} | máx {3} | jitter {4,5:N1} ms | pérdida {5}%' -f $target, ($rt | Measure-Object -Average).Average, ($rt | Measure-Object -Minimum).Minimum, ($rt | Measure-Object -Maximum).Maximum, $j, [math]::Round(100 * $lost / $n)
}
function Get-NetDiag {
    $ad = Get-ActiveAdapter; if (-not $ad) { return @('No hay un adaptador físico activo.') }
    $l = @("Adaptador : $($ad.Name) - $($ad.InterfaceDescription)", "Velocidad : $($ad.LinkSpeed) | driver $($ad.DriverVersionString) ($(Fmt-Date $ad.DriverDate))")
    $rss = Get-NetAdapterRss -Name $ad.Name -ErrorAction SilentlyContinue; if ($rss) { $l += "RSS       : $($rss.Enabled)" }
    $pm = Get-NetAdapterPowerManagement -Name $ad.Name -ErrorAction SilentlyContinue; if ($pm) { $l += "Ahorro de energía (apagar el dispositivo): $($pm.AllowComputerToTurnOffDevice)" }
    foreach ($kw in '*InterruptModeration', '*EEE', '*FlowControl', '*ReceiveBuffers', '*TransmitBuffers', '*LsoV2IPv4', '*TCPChecksumOffloadIPv4', '*JumboPacket') {
        $p = Get-NetAdapterAdvancedProperty -Name $ad.Name -RegistryKeyword $kw -ErrorAction SilentlyContinue
        if ($p) { $l += "{0,-34} {1}" -f $p.DisplayName, $p.DisplayValue }
    }
    $t = Get-NetTCPSetting -SettingName Internet -ErrorAction SilentlyContinue
    if ($t) { $l += "TCP        : autotuning $($t.AutoTuningLevelLocal) | congestión $($t.CongestionProvider) | ECN $($t.EcnCapability)" }
    $l
}
function Get-StoDiag {
    $l = @()
    foreach ($d in @(Get-PhysicalDisk -ErrorAction SilentlyContinue)) {
        $rel = $d | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
        $t = if ($rel -and $rel.Temperature) { "$($rel.Temperature) °C" } else { 'temp s/d' }
        $wr = if ($rel -and $null -ne $rel.Wear) { " | desgaste $($rel.Wear)%" } else { '' }
        $l += "$($d.FriendlyName) | $($d.MediaType)/$($d.BusType) | $([math]::Round($d.Size/1GB)) GB | salud $($d.HealthStatus) | firmware $($d.FirmwareVersion) | $t$wr"
    }
    foreach ($v in @(Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' })) {
        $pct = [math]::Round(100 * $v.SizeRemaining / $v.Size)
        $l += "$($v.DriveLetter): libre $([math]::Round($v.SizeRemaining/1GB)) GB ($pct%)" + $(if ($pct -lt 15) { '   <- poco espacio libre: perjudica al SSD' } else { '' })
    }
    $trim = (fsutil behavior query DisableDeleteNotify | Out-String)
    $l += 'TRIM : ' + $(if ($trim -match '=\s*0') { 'activado' } else { 'REVISAR -> ' + $trim.Trim() })
    $ws = Get-Service WSearch -ErrorAction SilentlyContinue; if ($ws) { $l += "Windows Search: $($ws.Status) / inicio $($ws.StartType)" }
    if (Get-Process OneDrive -ErrorAction SilentlyContinue) { $l += 'OneDrive : en ejecución (sincroniza en segundo plano)' }
    $nv = Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue | Where-Object { $_.DeviceName -match 'NVM Express|Standard NVM' } | Select-Object -First 1
    if ($nv) { $l += "Driver NVMe: $($nv.DeviceName) $($nv.DriverVersion) ($($nv.DriverProviderName))" }
    $l += 'Archivos de juegos: instalalos en el SSD más rápido con espacio libre; la caché de shaders no se borra salvo que haya stutter tras cambiar el driver.'
    $l
}
function Get-SecDiag {
    $l = @()
    $dg = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction SilentlyContinue
    if ($dg) {
        $vbs = switch ([int]$dg.VirtualizationBasedSecurityStatus) { 0 { 'apagado' } 1 { 'habilitado, sin correr' } 2 { 'corriendo' } default { 'desconocido' } }
        $hv = if (@($dg.SecurityServicesRunning) -contains 2) { 'ACTIVA' } else { 'inactiva' }
        $l += "VBS (seguridad basada en virtualización): $vbs", "Integridad de memoria (HVCI): $hv"
    } else { $l += 'No se pudo leer el estado de VBS/HVCI.' }
    foreach ($f in 'Microsoft-Hyper-V-All', 'VirtualMachinePlatform', 'HypervisorPlatform') {
        $x = Get-WindowsOptionalFeature -Online -FeatureName $f -ErrorAction SilentlyContinue
        if ($x) { $l += "$f : $($x.State)" }
    }
    $l += 'Hypervisor presente: ' + (Get-CimInstance Win32_ComputerSystem).HypervisorPresent
    $mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($mp) { $l += "Defender: protección en tiempo real = $($mp.RealTimeProtectionEnabled)" }
    $l
}
function Get-Baseline {
    $l = New-Object Collections.Generic.List[string]
    $os = Get-CimInstance Win32_OperatingSystem; $cs = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
    Pump; $l.Add('== SISTEMA ==')
    $l.Add("Windows : $($os.Caption) $($cv.DisplayVersion) (build $($os.BuildNumber).$($cv.UBR))")
    $l.Add("CPU     : $($cpu.Name -replace '\s+',' ') | $($cpu.NumberOfCores) núcleos / $($cpu.NumberOfLogicalProcessors) hilos | base $($cpu.MaxClockSpeed) MHz")
    $ram = @(Get-CimInstance Win32_PhysicalMemory)
    $spd = ($ram | ForEach-Object { $_.ConfiguredClockSpeed } | Select-Object -Unique) -join '/'
    $l.Add("RAM     : $([math]::Round($cs.TotalPhysicalMemory/1GB,1)) GB | $($ram.Count) módulos | configurada $spd MHz")
    $nom = ($ram | ForEach-Object { $_.Speed } | Measure-Object -Maximum).Maximum; $cfg = ($ram | ForEach-Object { $_.ConfiguredClockSpeed } | Measure-Object -Maximum).Maximum
    if ($nom -and $cfg -and $cfg -lt $nom) { $l.Add("          Aviso: la RAM corre a $cfg MHz y su velocidad nominal es $nom MHz (XMP/EXPO se activa en BIOS; Porte no la toca)") }
    foreach ($g in @(Get-CimInstance Win32_VideoController)) {
        $l.Add("GPU     : $($g.Name) | driver $($g.DriverVersion) ($(Fmt-Date $g.DriverDate)) | pantalla $($g.CurrentHorizontalResolution)x$($g.CurrentVerticalResolution) @ $($g.CurrentRefreshRate) Hz")
    }
    $live = Get-GpuLive; if ($live) { $l.Add("GPU vivo: $live") }
    Pump; $l.Add('== ALMACENAMIENTO ==')
    foreach ($x in (Get-StoDiag | Select-Object -First 6)) { $l.Add($x) }
    Pump; $l.Add('== CONFIGURACIÓN ACTUAL ==')
    $l.Add('Plan de energía : ' + ([regex]::Match((powercfg /getactivescheme | Out-String), '\(([^)]+)\)').Groups[1].Value))
    $l.Add("HAGS (HwSchMode): $(Nz (Get-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode'))   (2 = activado, 1 = desactivado)")
    $l.Add("Modo Juego      : $(Nz (Get-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled'))")
    $l.Add("Captura en 2º plano (AppCaptureEnabled): $(Nz (Get-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled'))")
    $l.Add("Opt. juegos en ventana: $(Nz (Get-Reg 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' 'DirectXUserGlobalSettings'))")
    $l.Add("Win32PrioritySeparation: $(Nz (Get-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation'))")
    Pump; $l.Add('== CARGA ACTUAL ==')
    $pc = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq '_Total' } | Select-Object -First 1
    if ($pc) { $l.Add("CPU en uso: $($pc.PercentProcessorTime)%") }
    $l.Add("RAM en uso: $([math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/1MB,1)) GB de $([math]::Round($os.TotalVisibleMemorySize/1MB,1)) GB")
    $ct = Get-CpuTemp; $l.Add('Temp. CPU (ACPI, poco fiable; usá HWiNFO): ' + $(if ($ct) { "$ct °C" } else { 's/d' }))
    $dp = Measure-Dpc; if ($dp) { $l.Add("DPC total: $($dp.Dpc)% | Interrupciones: $($dp.Int)%") }
    Pump; $l.Add('== SEGUNDO PLANO ==')
    $ov = @('Discord', 'steamwebhelper', 'GameBarPresenceWriter', 'XboxPcApp', 'nvsphelper64', 'RTSS', 'MSIAfterburner', 'OneDrive', 'Teams', 'ms-teams', 'Overwolf', 'Medal', 'obs64', 'Spotify', 'EpicGamesLauncher', 'Battle.net', 'RiotClientServices', 'EADesktop', 'iCUE', 'LGHUB', 'Wallpaper64', 'wallpaper32')
    $run = @(Get-Process -Name $ov -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName -Unique)
    $l.Add('Overlays/launchers abiertos: ' + $(if ($run.Count) { $run -join ', ' } else { 'ninguno de la lista' }))
    $l.Add("Programas de inicio: $(@(Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue).Count) | Servicios corriendo: $(@(Get-Service | Where-Object { $_.Status -eq 'Running' }).Count) | Procesos: $(@(Get-Process).Count)")
    Pump; $l.Add('== TIMERS ==')
    foreach ($x in (Get-TimerInfo | Select-Object -First 5)) { $l.Add($x) }
    @{ Fecha = (Get-Date -Format s); Lineas = @($l) } | ConvertTo-Json -Depth 3 | Set-Content $script:BaseFile -Encoding UTF8
    $l.Add(''); $l.Add("Baseline guardado en $script:BaseFile")
    $l -join "`n"
}

# ---------- Benchmark ----------
function Measure-Jitter {
    $sw = [Diagnostics.Stopwatch]::new(); $l = New-Object Collections.Generic.List[double]
    1..250 | ForEach-Object { $sw.Restart(); [Threading.Thread]::Sleep(1); $l.Add($sw.Elapsed.TotalMilliseconds); if ($_ % 25 -eq 0) { Pump } }
    $o = $l | Sort-Object
    [pscustomobject]@{ Avg = [math]::Round(($l | Measure-Object -Average).Average, 3); P99 = [math]::Round($o[[int]($o.Count * 0.99) - 1], 3) }
}
function Measure-Cpu {
    $sw = [Diagnostics.Stopwatch]::StartNew(); $n = 0; $x = 1.0
    while ($sw.ElapsedMilliseconds -lt 2000) { for ($i = 0; $i -lt 20000; $i++) { $x = [math]::Sqrt($x + $i) }; $n++; if ($n % 4 -eq 0) { Pump } }
    $n
}
function Measure-Dpc {
    $d = @(); $q = @()
    1..4 | ForEach-Object {
        $p = Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq '_Total' } | Select-Object -First 1
        if ($p) { $d += [double]$p.PercentDPCTime; $q += [double]$p.PercentInterruptTime }
        Wait-Ui 800
    }
    if ($d.Count) { [pscustomobject]@{ Dpc = [math]::Round(($d | Measure-Object -Average).Average, 2); Int = [math]::Round(($q | Measure-Object -Average).Average, 2) } } else { $null }
}
function Format-Cur {
    $c = $script:Cur; $l = @()
    if ($c.jitterAvg) { $l += "Jitter Sleep(1): promedio $($c.jitterAvg) ms | p99 $($c.jitterP99) ms" }
    if ($c.cpu) { $l += "Puntaje CPU (relativo): $($c.cpu)" }
    if ($null -ne $c.dpc) { $l += "DPC: $($c.dpc)% | Interrupciones: $($c.intr)%" }
    if ($c.fpsAvg) { $l += "FPS promedio: $($c.fpsAvg) | 1% low: $($c.low1) | 0.1% low: $($c.low01) | Stutters: $($c.stutters)" }
    if ($c.mode) { $l += "Modo de presentación real: $($c.mode)" }
    if ($l.Count) { $l -join "`n" } else { 'Todavía no mediste nada.' }
}
function Save-Bench($slot) {
    $j = @{}; if (Test-Path $script:BenchFile) { $o = Get-Content $script:BenchFile -Raw | ConvertFrom-Json; foreach ($p in $o.PSObject.Properties) { $j[$p.Name] = $p.Value } }
    $j[$slot] = $script:Cur
    $j | ConvertTo-Json -Depth 4 | Set-Content $script:BenchFile -Encoding UTF8
    Say "Guardado como $slot."
}
function Compare-Bench {
    if (-not (Test-Path $script:BenchFile)) { return 'Guardá un ANTES y un DESPUÉS primero.' }
    $j = Get-Content $script:BenchFile -Raw | ConvertFrom-Json
    if (-not $j.antes -or -not $j.despues) { return 'Falta guardar el ANTES o el DESPUÉS.' }
    $defs = @(@('jitterP99','Jitter p99 (ms)',$false),@('cpu','Puntaje CPU',$true),@('dpc','DPC %',$false),@('intr','Interrupciones %',$false),@('fpsAvg','FPS promedio',$true),@('low1','1% low',$true),@('low01','0.1% low',$true),@('stutters','Stutters',$false))
    $out = foreach ($d in $defs) {
        $a = $j.antes.($d[0]); $b = $j.despues.($d[0])
        if ($null -ne $a -and $null -ne $b -and $a -ne 0) {
            $pct = [math]::Round((($b - $a) / $a) * 100, 1)
            $mejor = if ($d[2]) { $pct -gt 0 } else { $pct -lt 0 }
            $v = if ($pct -eq 0) { '=' } elseif ($mejor) { 'mejor' } else { 'peor' }
            '{0,-22} {1} -> {2}  ({3}%) {4}' -f $d[1], $a, $b, $pct, $v
        }
    }
    if ($out) { (($out -join "`n") + "`n`nRegla: mantené solo lo que mejora. Si empeoró, 'Revertir todo'.") } else { 'No hay métricas en común entre el ANTES y el DESPUÉS.' }
}

# =====================================================================
#   PAGINAS
# =====================================================================
New-Page 'home'  0xE80F 'Inicio'         'Inicio'          'Baseline del equipo y método de prueba: un cambio por vez.' $false
New-Page 'win'   0xE713 'Windows'        'Windows'         'Game Mode, capturas, optimizaciones gráficas y políticas. Cada ajuste indica fase, evidencia y riesgo.' $true
New-Page 'cpu'   0xE945 'CPU y energía'  'CPU y energía'   'Planes de energía, boost, timers e input. Cada ajuste indica fase, evidencia y riesgo.' $true
New-Page 'lat'   0xE916 'Latencia'       'Latencia'        'DPC/ISR, timers e interrupciones. Se mide antes de corregir.' $true
New-Page 'net'   0xE839 'Red'            'Red'             'Estabilidad y latencia: ping, jitter, pérdida y red local son cosas distintas.' $true
New-Page 'gpu'   0xE7F4 'GPU y pantalla' 'GPU y pantalla'  'Driver, configuración según tu caso y pipeline de pantalla.' $false
New-Page 'sto'   0xEDA2 'Almacenamiento' 'Almacenamiento'  'Salud del SSD, espacio, TRIM, indexado y limpieza.' $true
New-Page 'deb'   0xE74D 'Debloat'        'Debloat'         'Verde: seguro si no lo usás. Amarillo: depende. Rojo: no tocar. Objetivo: menos contención, no menos procesos.' $true
New-Page 'sec'   0xE72E 'Seguridad'      'Seguridad'       'Seguridad perdida contra ganancia real. Nada se apaga solo.' $true
New-Page 'tmp'   0xE706 'Temperaturas'   'Temperaturas'    'Si hay thermal throttling, se arregla antes que cualquier tweak de Windows.' $false
New-Page 'game'  0xE7FC 'Juegos'         'Juegos'          'Configuración individual por juego: prioridad, GPU y pantalla completa.' $true
New-Page 'bench' 0xE9D9 'Benchmark'      'Benchmark'       'Medí antes y después. Si empeora, revertís.' $false
New-Page 'plan'  0xE8A5 'Plan'           'Plan por fases'  'Qué hacer, en qué orden, con qué riesgo y cómo medirlo.' $false

# =====================================================================
#   CATALOGO  (Ph 0 = no se aplica: NO vale la pena / Manual)
# =====================================================================
$script:Cat = @(
 # ---------------- WINDOWS ----------------
 @{Pg='win';Ph=1;N='Punto de restauración';Ev='Probado';Rk='Bajo';Mod='Crea un punto de restauración del sistema';Why='Red de seguridad antes de cambiar nada. Windows permite uno cada 24 h por defecto.';Gn='Ninguna (es seguridad)';M='NA';Rv='Restaurar sistema de Windows';A={ Enable-ComputerRestore -Drive "$env:SystemDrive\"; Checkpoint-Computer -Description 'Porte Tweaking' -RestorePointType MODIFY_SETTINGS }},
 @{Pg='win';Ph=1;N='Modo Juego de Windows';Ev='Probado';Rk='Bajo';Mod='HKCU\Software\Microsoft\GameBar: AutoGameModeEnabled=1';Why='Windows prioriza el juego en primer plano y evita instalar drivers por Windows Update mientras jugás.';Gn='Pequeña y variable';A={ Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1; Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1 }},
 @{Pg='win';Ph=1;N='Game Bar, capturas y grabación en 2º plano OFF';Ev='Probado';Rk='Bajo';Mod='GameDVR_Enabled, AppCaptureEnabled y HistoricalCaptureEnabled en 0';Why='Evita el codificador de captura que consume GPU y CPU en segundo plano.';Gn='Pequeña; mayor en equipos justos';A={ Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'HistoricalCaptureEnabled' 0 }},
 @{Pg='win';Ph=1;N='Widgets y Noticias OFF';Ev='Probado';Rk='Bajo';Mod='Política HKLM\SOFTWARE\Policies\Microsoft\Dsh: AllowNewsAndInterests=0';Why='Menos procesos residentes (WebView) y menos actividad de red en segundo plano.';Gn='Pequeña (menos contención en reposo)';A={ Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0 }},
 @{Pg='win';Ph=2;N='Optimizaciones para juegos en ventana + VRR en ventana';Ev='Depende: medir';Rk='Bajo';Mod='HKCU\Software\Microsoft\DirectX\UserGpuPreferences: SwapEffectUpgradeEnable=1;VRROptimizeEnable=1';Why='Convierte juegos DX10/11 de modo ventana o borderless a flip model, lo que permite DirectFlip y VRR en ventana.';Hw='Windows 11 22H2 o superior, juegos DX10/11';Gn='Menor latencia en DX10/11 en ventana; nula en DX12/Vulkan';A={ Set-Reg 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' 'DirectXUserGlobalSettings' 'SwapEffectUpgradeEnable=1;VRROptimizeEnable=1;' 'String' }},
 @{Pg='win';Ph=2;N='Programación de GPU por hardware (HAGS)';Ev='Depende: medir';Rk='Bajo';Mod='HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers: HwSchMode=2 (requiere reiniciar)';Why='La GPU gestiona su propia cola de trabajo en vez de la CPU. En algunos juegos mejora los lows y en otros empeora.';Hw='NVIDIA GTX 10xx o superior, AMD RX 5600 o superior, driver WDDM 2.7+';Gn='Variable: a veces positiva, a veces negativa';A={ Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2 }},
 @{Pg='win';Ph=3;N='Prioridad de primer plano (Win32PrioritySeparation = 38)';Ev='Depende: medir';Rk='Bajo';Mod='HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl: Win32PrioritySeparation=0x26';Why='Cambia el quantum y el refuerzo del hilo en primer plano. El valor 0x26 es popular pero la evidencia independiente es escasa.';Gn='Incierta; muchas veces nula';A={ Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38 }},
 @{Pg='win';Ph=5;N='MPO desactivado (OverlayTestMode = 5)';Ev='Depende: medir';Rk='Medio';Mod='HKLM\SOFTWARE\Microsoft\Windows\Dwm: OverlayTestMode=5 (requiere reiniciar)';Why='Solo si hay parpadeo o stutter con varios monitores o con una versión de driver con problemas de MPO. Si no hay problema, dejalo como está.';Hw='Multi-monitor o driver con bug de MPO';Gn='Solo corrige problemas puntuales';A={ Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode' 5 }},
 @{Pg='win';Ph=0;N='Desactivar telemetría "para ganar FPS"';Ev='NO vale la pena';Rk='Bajo';Mod='AllowTelemetry';Why='No cambia FPS ni frametime de forma medible. Es una decisión de privacidad, no de rendimiento.';Gn='Nula en FPS'},
 @{Pg='win';Ph=0;N='Tweaks de MMCSS ("Games", SystemResponsiveness)';Ev='NO vale la pena';Rk='Bajo';Mod='HKLM\...\Multimedia\SystemProfile';Why='Windows ya usa valores cercanos a los recomendados y no hay mediciones independientes que respalden cambiarlos.';Gn='Nula medible'},
 @{Pg='win';Ph=0;N='Desactivar optimizaciones de pantalla completa en todo el sistema';Ev='NO vale la pena';Rk='Bajo';Mod='AppCompatFlags';Why='Se decide por juego (pestaña Juegos) y se verifica con el modo de presentación real que reporta PresentMon.';Gn='Depende del juego'},
 # ---------------- CPU Y ENERGIA ----------------
 @{Pg='cpu';Ph=1;N='USB sin suspensión selectiva';Ev='Probado';Rk='Bajo';Mod='Plan Porte: USB selective suspend = 0';Why='Evita que mouse y teclado entren en ahorro de energía y tarden en responder.';Gn='Evita micro-cortes; no sube FPS';M='LAT';A={ $g = Get-PortePlan; powercfg /setacvalueindex $g 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0; powercfg /setactive $g }},
 @{Pg='cpu';Ph=1;N='Mouse sin aceleración';Ev='Probado';Rk='Bajo';Mod='HKCU\Control Panel\Mouse: MouseSpeed, MouseThreshold1 y MouseThreshold2 en 0';Why='Desactiva "mejorar precisión del puntero": el movimiento pasa a ser lineal y consistente. Se nota al reiniciar sesión.';Gn='Consistencia de puntería; no reduce latencia';M='LAT';A={ $p = 'HKCU:\Control Panel\Mouse'; Set-Reg $p 'MouseSpeed' '0' 'String'; Set-Reg $p 'MouseThreshold1' '0' 'String'; Set-Reg $p 'MouseThreshold2' '0' 'String' }},
 @{Pg='cpu';Ph=2;N='Boost agresivo del CPU';Ev='Depende: medir';Rk='Bajo';Mod='Plan Porte: PERFBOOSTMODE = 2 (Aggressive)';Why='El procesador sube a frecuencias de boost más rápido, según la documentación de Microsoft del ajuste.';Hw='CPU con boost (Intel Turbo, AMD Precision Boost)';Gn='Variable; más relevante en CPUs que bajan mucho de reloj';A={ $g = Get-PortePlan; powercfg /setacvalueindex $g SUB_PROCESSOR PERFBOOSTMODE 2; powercfg /setactive $g }},
 @{Pg='cpu';Ph=2;N='PCIe sin ahorro de energía (ASPM OFF)';Ev='Depende: medir';Rk='Bajo';Mod='Plan Porte: PCI Express Link State Power Management = Off';Why='Evita que el enlace PCIe (GPU, NVMe) cambie de estado de energía y agregue latencia de despertar.';Gn='Pequeña; más calor en reposo';A={ $g = Get-PortePlan; powercfg /setacvalueindex $g SUB_PCIEXPRESS ASPM 0; powercfg /setactive $g }},
 @{Pg='cpu';Ph=3;N='Estado mínimo del procesador al 100%';Ev='Depende: medir';Rk='Medio';Mod='Plan Porte: PROCTHROTTLEMIN = 100';Why='Mantiene el CPU en frecuencia alta siempre. Puede estabilizar frametime en algunos equipos, con más calor y consumo.';Gn='Variable; puede ser nula';A={ $g = Get-PortePlan; powercfg /setacvalueindex $g SUB_PROCESSOR PROCTHROTTLEMIN 100; powercfg /setactive $g }},
 @{Pg='cpu';Ph=4;N='Resolución de timers global (GlobalTimerResolutionRequests)';Ev='Depende: medir';Rk='Medio';Mod='HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel: GlobalTimerResolutionRequests=1';Why='Desde Windows 10 2004 cada proceso tiene su propio timer. Este valor restaura el comportamiento global previo. Solo tiene sentido si un programa que pide 0,5 ms pierde ese efecto.';Gn='Incierta; verificala con el jitter de Sleep(1) del Benchmark';M='LAT';A={ Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' 'GlobalTimerResolutionRequests' 1 }},
 @{Pg='cpu';Ph=0;N='Core parking desactivado';Ev='NO vale la pena';Rk='Bajo';Mod='CPMINCORES=100';Why='En desktop los planes modernos ya mantienen los núcleos activos y no hay medición que muestre mejora.';Gn='Nula en la práctica'},
 @{Pg='cpu';Ph=0;N='Plan "Ultimate Performance" por sí solo';Ev='NO vale la pena';Rk='Bajo';Mod='Plan de energía oculto';Why='Es un plan con estados de reposo relajados. No significa más FPS automáticamente; si ayuda, ayuda por los ajustes concretos de arriba.';Gn='Depende; se mide con los ajustes individuales'},
 @{Pg='cpu';Ph=0;N='HPET encendido o apagado "siempre"';Ev='NO vale la pena';Rk='Medio';Mod='bcdedit useplatformclock';Why='Ni apagarlo ni encenderlo es siempre mejor. Se diagnostica qué usa Windows (pestaña Latencia) y se toca solo si hay un problema demostrable.';Gn='Depende del hardware'},
 @{Pg='cpu';Ph=0;N='Prioridad RealTime y afinidad manual global';Ev='NO vale la pena';Rk='Alto';Mod='Prioridades/afinidad';Why='RealTime puede congelar el sistema y fijar afinidades sin razón demostrable suele empeorar el scheduler, sobre todo en CPUs híbridas con P-cores y E-cores.';Gn='Negativa'},
 @{Pg='cpu';Ph=0;N='Tweaks de colas de mouse/teclado (MouseDataQueueSize)';Ev='NO vale la pena';Rk='Medio';Mod='mouclass/kbdclass';Why='Sin evidencia de mejora de latencia en hardware actual y puede perder eventos de entrada.';Gn='Nula o negativa'},
 @{Pg='cpu';Ph=0;N='Polling rate del mouse';Ev='Manual';Rk='Bajo';Mod='Se configura en el mouse';Why='Se cambia con el software del fabricante o en el propio mouse. Subirlo aumenta la carga de CPU y de interrupciones: probalo con el Benchmark.';Gn='Depende'},
 @{Pg='cpu';Ph=0;N='CPUs híbridas (P-cores / E-cores)';Ev='Manual';Rk='Bajo';Mod='Thread Director + Windows 11';Why='Usá Windows 11, Modo Juego y drivers de chipset actualizados, y dejá que el scheduler decida. No fijes afinidades sin una razón demostrable.';Gn='Depende'},
 # ---------------- LATENCIA ----------------
 @{Pg='lat';Ph=0;N='MSI Mode en todos los dispositivos';Ev='NO vale la pena';Rk='Medio';Mod='MessageSignaledInterruptProperties';Why='Los drivers modernos de GPU y NVMe ya lo usan. Se prueba dispositivo por dispositivo y solo si el driver lo declara.';Gn='Nula si ya está activo'},
 @{Pg='lat';Ph=0;N='Mover todas las interrupciones al CPU 0';Ev='NO vale la pena';Rk='Alto';Mod='Interrupt affinity';Why='Concentra toda la carga en un núcleo y puede crear el problema que se quería evitar.';Gn='Negativa'},
 # ---------------- RED ----------------
 @{Pg='net';Ph=2;N='Ahorro de energía del adaptador OFF';Ev='Probado';Rk='Bajo';Mod='Adaptador activo: "Permitir que el equipo apague este dispositivo" = desactivado';Why='Evita micro-desconexiones y retrasos de despertar del adaptador.';Hw='Cualquier adaptador';Gn='Estabilidad; no baja el ping físico';M='NET';Rv='Porte: Revertir todo';A={ $ad = Get-ActiveAdapter; if (-not $ad) { throw 'No hay un adaptador activo.' }; $old = (Get-NetAdapterPowerManagement -Name $ad.Name).AllowComputerToTurnOffDevice; $script:Undo += [pscustomobject]@{ Kind='netpm'; Name=$ad.Name; Old=[string]$old }; Set-NetAdapterPowerManagement -Name $ad.Name -AllowComputerToTurnOffDevice Disabled }},
 @{Pg='net';Ph=2;N='Energy Efficient Ethernet OFF';Ev='Depende: medir';Rk='Bajo';Mod='Propiedad avanzada del driver: *EEE = 0';Why='EEE puede causar micro-cortes en algunos switches y routers. Solo aplica si el driver expone la opción.';Hw='Adaptador Ethernet con EEE';Gn='Estabilidad en casos puntuales';M='NET';A={ Set-AdvProp '*EEE' '0' }},
 @{Pg='net';Ph=4;N='Interrupt Moderation OFF';Ev='Depende: medir';Rk='Medio';Mod='Propiedad avanzada del driver: *InterruptModeration = 0';Why='Reduce el agrupamiento de interrupciones de red (menos latencia) a costa de más uso de CPU.';Hw='Adaptador que exponga la opción';Gn='Variable; mide jitter y DPC';M='LAT';A={ Set-AdvProp '*InterruptModeration' '0' }},
 @{Pg='net';Ph=0;N='Nagle, TcpAckFrequency y TCPNoDelay';Ev='NO vale la pena';Rk='Bajo';Mod='Claves de Tcpip\Parameters';Why='Afectan TCP y la mayoría de los juegos competitivos usan UDP. Efecto despreciable en juegos modernos.';Gn='Nula'},
 @{Pg='net';Ph=0;N='NetworkThrottlingIndex y tweaks globales de TCP';Ev='NO vale la pena';Rk='Medio';Mod='Registro / netsh';Why='No reducen el ping hacia el servidor. Windows ajusta autotuning por sí solo; apagarlo suele empeorar la descarga.';Gn='Nula o negativa'},
 @{Pg='net';Ph=0;N='Bufferbloat';Ev='Manual';Rk='Bajo';Mod='Se corrige en el router';Why='Se arregla con SQM (fq_codel o CAKE) en el router, no en Windows. Medilo con un test de bufferbloat web mientras descargás algo.';Gn='Alta si tu router lo permite'},
 # ---------------- GPU ----------------
 @{Pg='gpu';Ph=0;N='Instalación limpia del driver (DDU)';Ev='Manual';Rk='Medio';Mod='Desinstalación completa y driver nuevo';Why='Bajá el driver oficial, arrancá en Modo Seguro, limpiá con DDU, instalá el driver y configurá. Porte no lo automatiza porque exige Modo Seguro.';Gn='Soluciona stutters por drivers corruptos'},
 @{Pg='gpu';Ph=0;N='Reflex, Low Latency Mode, Anti-Lag';Ev='Manual';Rk='Bajo';Mod='Se configura en el juego y en el driver';Why='Usá el asistente de abajo: la configuración correcta depende de tu monitor, del juego y de si tu limitante es CPU o GPU.';Gn='Latencia menor, sobre todo si estás limitado por GPU'},
 @{Pg='gpu';Ph=0;N='Texture filtering, Threaded Optimization, Shader Cache';Ev='Manual';Rk='Bajo';Mod='Panel del driver';Why='Dejá los valores por defecto salvo que midas una mejora. No desactives el shader cache.';Gn='Normalmente nula'},
 # ---------------- ALMACENAMIENTO ----------------
 @{Pg='sto';Ph=2;N='Windows Search en modo manual';Ev='Depende: medir';Rk='Bajo';Mod='Servicio WSearch: Start=3';Why='Reduce la actividad de indexado en segundo plano. Perdés búsquedas instantáneas en el Explorador.';Gn='Pequeña; menos IO en segundo plano';M='DSK';A={ Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\WSearch' 'Start' 3 }},
 @{Pg='sto';Ph=0;N='Desactivar TRIM';Ev='NO vale la pena';Rk='Alto';Mod='fsutil';Why='TRIM mantiene el rendimiento sostenido del SSD. Nunca se desactiva.';Gn='Negativa'},
 @{Pg='sto';Ph=0;N='Desactivar SysMain/Prefetch en SSD';Ev='NO vale la pena';Rk='Bajo';Mod='Servicio SysMain';Why='En SSD el efecto es despreciable y puede empeorar la carga de aplicaciones.';Gn='Nula'},
 @{Pg='sto';Ph=0;N='Desactivar el archivo de paginación';Ev='NO vale la pena';Rk='Alto';Mod='Memoria virtual';Why='Provoca cierres de juegos y aplicaciones que reservan memoria. No da FPS.';Gn='Negativa'},
 @{Pg='sto';Ph=0;N='Exclusión de Defender para la carpeta de juegos';Ev='Manual';Rk='Medio';Mod='Seguridad de Windows > Exclusiones';Why='Reduce escaneos al cargar juegos pero deja esa carpeta sin vigilancia. Decisión tuya; no se desactiva Defender.';Gn='Pequeña'},
 # ---------------- SEGURIDAD ----------------
 @{Pg='sec';Ph=5;N='Integridad de memoria (HVCI) apagada';Ev='Depende: medir';Rk='Alto';Mod='HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity: Enabled=0 (requiere reiniciar)';Why='Quita la validación de código del kernel que hace Windows con virtualización.';Hw='CPU/juegos donde VBS cueste FPS';Gn='Entre 3% y 6% de FPS promedio en pruebas de Tom''s Hardware; algunos juegos más';M='SEC';Loss='Drivers vulnerables y malware a nivel kernel quedan más expuestos. Algunos anti-cheats exigen HVCI activo.';A={ Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled' 0 }},
 @{Pg='sec';Ph=5;N='VBS completo apagado';Ev='Depende: medir';Rk='Alto';Mod='HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard: EnableVirtualizationBasedSecurity=0 (requiere reiniciar)';Why='Apaga la seguridad basada en virtualización completa. Si el bloqueo UEFI o una política la reactivan, el cambio no se aplica.';Hw='CPU/juegos donde VBS cueste FPS';Gn='Alrededor de 3 a 7% en pruebas publicadas; depende de CPU y juego';M='SEC';Loss='Desaparecen VBS, HVCI y Credential Guard: menos aislamiento ante malware y robo de credenciales.';A={ Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity' 0 }},
 @{Pg='sec';Ph=5;N='Hypervisor de Windows apagado (bcdedit)';Ev='Depende: medir';Rk='Alto';Mod='bcdedit /set hypervisorlaunchtype off (requiere reiniciar)';Why='Evita que Windows arranque sobre el hypervisor. Solo tiene sentido si no usás virtualización.';Hw='Equipos sin WSL2, Docker, Hyper-V ni Sandbox';Gn='Pequeña';M='SEC';Rv='Porte: Revertir todo (bcdedit /set hypervisorlaunchtype auto)';Loss='Dejan de funcionar WSL2, Hyper-V, Windows Sandbox, Docker y emuladores con virtualización; VBS también depende del hypervisor.';A={ $script:Undo += [pscustomobject]@{ Kind='hv' }; bcdedit /set hypervisorlaunchtype off | Out-Null }},
 @{Pg='sec';Ph=0;N='Desactivar Windows Defender de forma permanente';Ev='NO vale la pena';Rk='Alto';Mod='Políticas de Defender';Why='La ganancia de rendimiento no justifica quedar sin antivirus. Si querés menos escaneos, usá exclusiones puntuales.';Gn='Pequeña frente al riesgo'},
 # ---------------- TEMPERATURAS ----------------
 @{Pg='tmp';Ph=0;N='Curvas de ventilador y voltaje';Ev='Manual';Rk='Medio';Mod='Software del fabricante / BIOS';Why='Windows no controla ventiladores ni voltajes de forma genérica. Porte mide temperatura y reloj sostenido y te dice si hay throttling; la corrección es física o de BIOS.';Gn='Alta si hay throttling'}
)

# ---------- Texto de cada ajuste ----------
function Get-TwFields($t) {
    @{
        Hw = $(if ($t.Hw) { $t.Hw } else { 'Cualquiera' })
        Gn = $(if ($t.Gn) { $t.Gn } else { 'Variable' })
        Rv = $(if ($t.Rv) { $t.Rv } else { 'Porte: Revertir todo' })
        M  = $(if ($t.M) { $script:MM[$t.M] } else { $script:MM['FT'] })
    }
}
function Get-TwText($t) {
    $f = Get-TwFields $t
    $s = "Qué modifica: $($t.Mod)`nPor qué: $($t.Why)`nHardware: $($f.Hw)`nGanancia posible: $($f.Gn)`nRiesgo: $($t.Rk)`nCómo medirlo: $($f.M)`nCómo revertirlo: $($f.Rv)"
    if ($t.Loss) { $s += "`nSeguridad perdida: $($t.Loss)" }
    $s
}
function Add-TwCard($t) {
    $pg = $script:Pages[$t.Pg]
    $tag = if ($t.Tag) { $t.Tag } elseif ($t.Ph -gt 0) { "Fase $($t.Ph) · $($t.Ev) · Riesgo $($t.Rk)" } else { $t.Ev }
    $color = $t.Col
    if (-not $color) { $color = switch -Wildcard ($t.Ev) { 'NO vale*' { '#F06A6A' } 'Probado*' { '#5ED38A' } 'Depende*' { '#E8C45A' } default { $null } } }
    if ($t.A) { $cb = New-Object Windows.Controls.CheckBox; $cb.Style = $w.FindResource('Switch'); $cb.Tag = $t; $script:checks += $cb; $ctrl = $cb }
    else { $lbl = if ($t.Lbl) { $t.Lbl } elseif ($t.Ev -like 'NO vale*') { 'NO aplicar' } else { 'Manual' }; $ctrl = Nil $lbl }
    $pg.Grid.Children.Add((New-Card $t.N $t.Why $ctrl $tag $color (Get-TwText $t))) | Out-Null
}
foreach ($t in $script:Cat) { Add-TwCard $t }

# =====================================================================
#   CARGA PEREZOSA (Debloat y MSI se analizan al abrir la pestaña)
# =====================================================================
$script:Lazy = @{}
function Go($k) {
    if ($script:Lazy.ContainsKey($k)) { $b = $script:Lazy[$k]; $script:Lazy.Remove($k); Say 'Analizando el equipo...'; try { & $b } catch { Say ('Error al analizar: ' + $_.Exception.Message) } }
    foreach ($p in $script:Pages.Values) { $p.Panel.Visibility = 'Collapsed' }
    $pg = $script:Pages[$k]; $pg.Panel.Visibility = 'Visible'
    $PageTitle.Text = $pg.Title; $PageSub.Text = $pg.Sub
    $Footer.Visibility = if ($pg.Footer) { 'Visible' } else { 'Collapsed' }
    $script:CurPage = $k
}
function Class-Col($c) { switch ($c) { 'VERDE' { '#5ED38A' } 'AMARILLO' { '#E8C45A' } default { '#F06A6A' } } }
function Class-Txt($c) { switch ($c) { 'VERDE' { 'VERDE · Seguro si no lo usás' } 'AMARILLO' { 'AMARILLO · Depende del usuario' } default { 'ROJO · No tocar' } } }
function Get-Class($name, $cmd) {
    $s = "$name $cmd"
    if ($s -match 'SecurityHealth|Defender|Realtek|RtkAudio|Audio|NVIDIA|AMD|Radeon|Intel|Bluetooth|Synaptics|Touchpad|Windows Security') { return 'ROJO' }
    if ($s -match 'Teams|Skype|Edge|Adobe|Java|Google ?Update|Cortana|Spotify|CCleaner|Dropbox') { return 'VERDE' }
    'AMARILLO'
}
function Get-StartupItems {
    $srcs = @(
        @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'),
        @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run')
    )
    foreach ($s in $srcs) {
        $k = Get-Item $s[0] -ErrorAction SilentlyContinue; if (-not $k) { continue }
        foreach ($n in $k.GetValueNames()) {
            if (-not $n) { continue }
            $ap = Get-Reg $s[1] $n
            $dis = ($ap -is [byte[]]) -and ($ap.Count -gt 0) -and (($ap[0] % 2) -eq 1)
            [pscustomobject]@{ Name = $n; Cmd = [string]$k.GetValue($n); Ap = $s[1]; Disabled = $dis }
        }
    }
}
function Build-Deb {
    foreach ($it in @(Get-StartupItems)) {
        $c = Get-Class $it.Name $it.Cmd
        $t = @{ Pg='deb'; Ph=1; N="Inicio: $($it.Name)"; Ev=''; Rk='Bajo'; Mod="StartupApproved: $($it.Cmd)"; Why=$(if ($it.Disabled) { 'Ya está desactivado al inicio.' } else { 'Se abre en cada arranque y ocupa CPU, RAM y disco en segundo plano.' }); Gn='Menos contención en segundo plano'; M='DSK'; Tag=(Class-Txt $c); Col=(Class-Col $c); Ap=$it.Ap; Nm=$it.Name }
        if ($c -ne 'ROJO' -and -not $it.Disabled) { $t.A = { param($x) Set-Reg $x.Ap $x.Nm ([byte[]](3,0,0,0,0,0,0,0,0,0,0,0)) 'Binary' } } else { $t.Lbl = $(if ($it.Disabled) { 'Ya desactivado' } else { 'No tocar' }) }
        Add-TwCard $t
    }
    $svcs = @(@('Fax','Servicio de fax','VERDE','Casi nadie lo usa.'), @('MapsBroker','Mapas descargados','VERDE','Solo se usa con mapas sin conexión.'), @('RetailDemo','Modo demo de tienda','VERDE','Solo sirve en equipos de exhibición.'), @('DiagTrack','Telemetría (DiagTrack)','AMARILLO','No da FPS; reduce actividad de disco y red. Algunos informes de error dejan de enviarse.'))
    foreach ($sv in $svcs) {
        if (-not (Get-Service -Name $sv[0] -ErrorAction SilentlyContinue)) { continue }
        $t = @{ Pg='deb'; Ph=1; N="Servicio: $($sv[1])"; Ev=''; Rk='Bajo'; Mod="HKLM\SYSTEM\CurrentControlSet\Services\$($sv[0]): Start=4 (requiere reiniciar)"; Why=$sv[3]; Gn='Pequeña'; M='DSK'; Tag=(Class-Txt $sv[2]); Col=(Class-Col $sv[2]); Svc=$sv[0] }
        $t.A = { param($x) Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\$($x.Svc)" 'Start' 4 }
        Add-TwCard $t
    }
    $tasks = @(@('\Microsoft\Windows\Application Experience\','Microsoft Compatibility Appraiser'), @('\Microsoft\Windows\Application Experience\','ProgramDataUpdater'), @('\Microsoft\Windows\Customer Experience Improvement Program\','Consolidator'), @('\Microsoft\Windows\Customer Experience Improvement Program\','UsbCeip'))
    foreach ($tk in $tasks) {
        $x = Get-ScheduledTask -TaskPath $tk[0] -TaskName $tk[1] -ErrorAction SilentlyContinue
        if (-not $x -or $x.State -eq 'Disabled') { continue }
        $t = @{ Pg='deb'; Ph=1; N="Tarea: $($tk[1])"; Ev=''; Rk='Bajo'; Mod="Tarea programada $($tk[0])$($tk[1])"; Why='Tarea de telemetría/compatibilidad que corre en segundo plano.'; Gn='Pequeña'; M='DSK'; Tag=(Class-Txt 'VERDE'); Col=(Class-Col 'VERDE'); TP=$tk[0]; TN=$tk[1] }
        $t.A = { param($x) Disable-ScheduledTask -TaskPath $x.TP -TaskName $x.TN | Out-Null; $script:Undo += [pscustomobject]@{ Kind='task'; Path=$x.TP; Name=$x.TN } }
        Add-TwCard $t
    }
    $apps = @(@('Microsoft.BingNews','Noticias de Microsoft'), @('Microsoft.BingWeather','Clima de Microsoft'), @('Microsoft.GetHelp','Obtener ayuda'), @('Microsoft.Getstarted','Consejos'), @('Microsoft.MicrosoftSolitaireCollection','Solitario'), @('Microsoft.WindowsFeedbackHub','Centro de opiniones'), @('Clipchamp.Clipchamp','Clipchamp'), @('MicrosoftTeams','Teams (consumo)'), @('Microsoft.549981C3F5F10','Cortana'))
    foreach ($ap in $apps) {
        if (-not (Get-AppxPackage -Name $ap[0] -ErrorAction SilentlyContinue)) { continue }
        $t = @{ Pg='deb'; Ph=1; N="App: $($ap[1])"; Ev=''; Rk='Bajo'; Mod="Quita el paquete $($ap[0]) del usuario actual"; Why='Se puede reinstalar desde Microsoft Store. Porte no lo revierte.'; Gn='Menos tareas y actualizaciones en segundo plano'; M='DSK'; Rv='Reinstalar desde Microsoft Store'; Tag='VERDE · Reinstalable desde la Store'; Col=(Class-Col 'VERDE'); Pkg=$ap[0] }
        $t.A = { param($x) Get-AppxPackage -Name $x.Pkg | Remove-AppxPackage -ErrorAction Stop }
        Add-TwCard $t
    }
    foreach ($r in @(@('Windows Update','Parches de seguridad y drivers.'), @('Windows Defender','No se desactiva de forma permanente.'), @('Audio, red, firewall, WMI y RPC','Servicios base: romperlos rompe el sistema.'), @('Gaming Services / Xbox Identity','Necesarios para Game Pass y juegos de la Store.'), @('Servicios de anti-cheat (EasyAntiCheat, BattlEye, Vanguard, FACEIT)','Sin ellos los juegos no abren.'))) {
        Add-TwCard @{ Pg='deb'; Ph=0; N=$r[0]; Ev='ROJO'; Rk='Alto'; Mod='Servicios y componentes críticos'; Why=$r[1]; Gn='Ninguna'; Tag=(Class-Txt 'ROJO'); Col=(Class-Col 'ROJO'); Lbl='No tocar' }
    }
    $oem = @(Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Armoury|SupportAssist|Vantage|MSI Center|Dragon Center|Synapse|iCUE|G HUB|Alienware|Nahimic' } | Select-Object -ExpandProperty DisplayName -Unique)
    if ($oem.Count) { Add-TwCard @{ Pg='deb'; Ph=0; N='Software del fabricante detectado'; Ev='AMARILLO'; Rk='Medio'; Mod='Programas instalados'; Why=($oem -join ', ') + '. Suelen correr servicios residentes; desinstalalos desde Configuración solo si no usás sus funciones (RGB, ventiladores, perfiles).'; Gn='Menos contención'; Tag=(Class-Txt 'AMARILLO'); Col=(Class-Col 'AMARILLO'); Lbl='Manual' } }
}
function Build-Msi {
    $devs = @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like 'PCI\*' -and $_.Class -in 'Display', 'Net', 'USB', 'SCSIAdapter', 'HDC' })
    foreach ($d in $devs) {
        $rp = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($d.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        $v = Get-Reg $rp 'MSISupported'
        if ($null -eq $v) { continue }
        $t = @{ Pg='lat'; Ph=4; N="MSI Mode: $($d.FriendlyName)"; Ev='Depende: medir'; Rk='Medio'; Mod='MessageSignaledInterruptProperties: MSISupported=1 (requiere reiniciar)'; Why=$(if ($v -eq 1) { 'Ya está activo. No hace falta tocarlo.' } else { 'Interrupciones por mensaje en vez de líneas compartidas. Probalo solo en este dispositivo y medí DPC antes y después.' }); Gn='Variable'; M='LAT'; RegPath=$rp }
        if ($v -eq 1) { $t.Lbl = 'Ya activo' } else { $t.A = { param($x) Set-Reg $x.RegPath 'MSISupported' 1 } }
        Add-TwCard $t
    }
    if (-not $devs.Count) { Add-Info 'lat' 'MSI Mode' 'No se encontraron dispositivos PCI con MSI configurable.' }
}
$script:Lazy['deb'] = { Build-Deb }
$script:Lazy['lat'] = { Build-Msi }

# =====================================================================
#   OVERLAY DE CARGA (fondo borroso + tarjeta animada)
# =====================================================================
$busyXaml = @'
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
      Visibility="Collapsed" Background="{DynamicResource BusyDim}">
  <Border Width="390" Height="250" CornerRadius="22" HorizontalAlignment="Center" VerticalAlignment="Center"
          Background="{DynamicResource BusyCard}" BorderBrush="{DynamicResource CardBorder}" BorderThickness="1">
    <Border.Effect><DropShadowEffect BlurRadius="45" ShadowDepth="0" Opacity="0.6" Color="Black"/></Border.Effect>
    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
      <Grid Width="92" Height="92" HorizontalAlignment="Center">
        <Ellipse Stroke="{DynamicResource CardBorder}" StrokeThickness="3"/>
        <Ellipse x:Name="Ring" Stroke="{DynamicResource AccentBrush}" StrokeThickness="4" StrokeDashArray="6 9" StrokeDashCap="Round" RenderTransformOrigin="0.5,0.5">
          <Ellipse.RenderTransform><RotateTransform/></Ellipse.RenderTransform>
        </Ellipse>
        <Ellipse x:Name="Ring2" Margin="16" Stroke="{DynamicResource MutedBrush}" StrokeThickness="2.5" StrokeDashArray="3 7" StrokeDashCap="Round" RenderTransformOrigin="0.5,0.5">
          <Ellipse.RenderTransform><RotateTransform/></Ellipse.RenderTransform>
        </Ellipse>
        <TextBlock Text="P" FontSize="30" FontWeight="Black" Foreground="{DynamicResource AccentBrush}" HorizontalAlignment="Center" VerticalAlignment="Center"/>
      </Grid>
      <TextBlock x:Name="BusyTitle" Text="Procesando" FontSize="18" FontWeight="SemiBold" Foreground="{DynamicResource TextBrush}" HorizontalAlignment="Center" Margin="0,22,0,3"/>
      <TextBlock x:Name="BusySub" Text="No cierres la ventana" FontSize="12" Foreground="{DynamicResource MutedBrush}" HorizontalAlignment="Center" TextAlignment="Center" TextWrapping="Wrap" MaxWidth="320"/>
      <Border Width="250" Height="4" CornerRadius="2" Background="{DynamicResource TrackOff}" Margin="0,20,0,0" ClipToBounds="True">
        <Border x:Name="Shimmer" Width="90" CornerRadius="2" HorizontalAlignment="Left" Background="{DynamicResource AccentBrush}">
          <Border.RenderTransform><TranslateTransform/></Border.RenderTransform>
        </Border>
      </Border>
    </StackPanel>
  </Border>
</Grid>
'@
$script:BusyOverlay = [Windows.Markup.XamlReader]::Parse($busyXaml)
$script:BusyTitle = $script:BusyOverlay.FindName('BusyTitle'); $script:BusySub = $script:BusyOverlay.FindName('BusySub')
$script:RingRot = $script:BusyOverlay.FindName('Ring').RenderTransform
$script:Ring2Rot = $script:BusyOverlay.FindName('Ring2').RenderTransform
$script:ShimX = $script:BusyOverlay.FindName('Shimmer').RenderTransform
$script:rootInner = $script:rootGrid.Children[2]
$script:rootGrid.Children.Add($script:BusyOverlay) | Out-Null
$script:BusyDepth = 0
function Start-BusyAnim {
    $a1 = [Windows.Media.Animation.DoubleAnimation]::new(0, 360, [TimeSpan]::FromSeconds(1.5)); $a1.RepeatBehavior = [Windows.Media.Animation.RepeatBehavior]::Forever
    $script:RingRot.BeginAnimation([Windows.Media.RotateTransform]::AngleProperty, $a1)
    $a2 = [Windows.Media.Animation.DoubleAnimation]::new(360, 0, [TimeSpan]::FromSeconds(2.4)); $a2.RepeatBehavior = [Windows.Media.Animation.RepeatBehavior]::Forever
    $script:Ring2Rot.BeginAnimation([Windows.Media.RotateTransform]::AngleProperty, $a2)
    $a3 = [Windows.Media.Animation.DoubleAnimation]::new(-95, 255, [TimeSpan]::FromSeconds(1.2)); $a3.RepeatBehavior = [Windows.Media.Animation.RepeatBehavior]::Forever
    $a3.EasingFunction = [Windows.Media.Animation.QuadraticEase]::new()
    $script:ShimX.BeginAnimation([Windows.Media.TranslateTransform]::XProperty, $a3)
}
function Stop-BusyAnim {
    $script:RingRot.BeginAnimation([Windows.Media.RotateTransform]::AngleProperty, $null)
    $script:Ring2Rot.BeginAnimation([Windows.Media.RotateTransform]::AngleProperty, $null)
    $script:ShimX.BeginAnimation([Windows.Media.TranslateTransform]::XProperty, $null)
}
function Show-Busy($title = 'Procesando', $sub = 'No cierres la ventana') {
    $script:BusyDepth++
    $script:BusyTitle.Text = $title; $script:BusySub.Text = $sub
    if ($script:BusyDepth -gt 1) { return }
    $be = [Windows.Media.Effects.BlurEffect]::new(); $be.Radius = 18
    $script:rootInner.Effect = $be
    $script:BusyOverlay.Visibility = 'Visible'
    Start-BusyAnim
    $w.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Render)
}
function Hide-Busy {
    if ($script:BusyDepth -gt 0) { $script:BusyDepth-- }
    if ($script:BusyDepth -gt 0) { return }
    Stop-BusyAnim
    $script:BusyOverlay.Visibility = 'Collapsed'
    $script:rootInner.Effect = $null
}

# =====================================================================
#   INICIO
# =====================================================================
try {
    $os = Get-CimInstance Win32_OperatingSystem; $cpuI = Get-CimInstance Win32_Processor | Select-Object -First 1; $cs = Get-CimInstance Win32_ComputerSystem; $up = (Get-Date) - $os.LastBootUpTime
    $info = @(@('SISTEMA', ($os.Caption -replace 'Microsoft ', '')), @('PROCESADOR', ($cpuI.Name -replace '\s+', ' ')), @('MEMORIA RAM', ('{0} GB' -f [math]::Round($cs.TotalPhysicalMemory / 1GB))), @('ENCENDIDO', ('{0}d {1}h {2}m' -f $up.Days, $up.Hours, $up.Minutes)))
} catch { $info = @(@('SISTEMA', 'Windows'), @('PROCESADOR', '-'), @('MEMORIA RAM', '-'), @('ENCENDIDO', '-')) }
$stats = New-Object Windows.Controls.Primitives.UniformGrid; $stats.Columns = 4
foreach ($i in $info) {
    $b = New-Object Windows.Controls.Border; $b.CornerRadius = [Windows.CornerRadius]::new(16); $b.Margin = [Windows.Thickness]::new(0,0,12,12); $b.Padding = [Windows.Thickness]::new(18); $b.BorderThickness = [Windows.Thickness]::new(1); $b.MinHeight = 100
    $b.SetResourceReference([Windows.Controls.Border]::BackgroundProperty, 'CardBrush'); $b.SetResourceReference([Windows.Controls.Border]::BorderBrushProperty, 'CardBorder')
    $s = New-Object Windows.Controls.StackPanel; $s.Children.Add((Tx $i[0] 10.5 'MutedBrush' 'SemiBold')) | Out-Null
    $v = Tx $i[1] 16 'TextBrush' 'Bold'; $v.Margin = [Windows.Thickness]::new(0,10,0,0); $s.Children.Add($v) | Out-Null; $b.Child = $s; $script:field.Targets.Add($b); $stats.Children.Add($b) | Out-Null
}
$script:Pages['home'].Panel.Children.Add($stats) | Out-Null
Add-Info 'home' 'Permisos' $(if ($isAdmin) { 'Ejecutando como administrador: todos los ajustes están disponibles.' } else { 'ATENCIÓN: no estás como administrador. Abrí PowerShell con "Ejecutar como administrador" para aplicar ajustes.' })
Add-DiagCard 'home' 'Diagnóstico inicial (baseline)' 'CPU, GPU, RAM, discos, timers, DPC, overlays y configuración actual. Hacelo ANTES de cambiar nada.' 'Crear baseline' { Get-Baseline }
Add-Info 'home' 'Método de prueba' "1. Baseline   2. Aplicar UN cambio   3. Reiniciar si hace falta`n4. Repetir el mismo escenario   5. Comparar 1% low, 0.1% low, frametime, DPC y temperatura`n6. Mantener solo lo que mejora   7. Revertir lo que empeora`nNo acumules 50 ajustes y después afirmes que funcionaron."

# =====================================================================
#   LATENCIA
# =====================================================================
Add-DiagCard 'lat' 'DPC / ISR por núcleo' 'Promedio de unos 5 segundos por núcleo, con aviso si se concentra en uno solo.' 'Medir' { Get-DpcCores }
Add-DiagCard 'lat' 'Timers' 'Resolución actual, bcdedit y HPET: qué usa Windows hoy y si hay un problema real.' 'Analizar' { Get-TimerInfo }
$bS = Pill 'Iniciar' 'Ghost'; $bE = Pill 'Detener y guardar'
$bp = New-Object Windows.Controls.StackPanel; $bp.Orientation = 'Horizontal'; $bS.Margin = [Windows.Thickness]::new(0,0,8,0); $bp.Children.Add($bS) | Out-Null; $bp.Children.Add($bE) | Out-Null
$dEtw = New-Diag 'Qué driver causa los picos (traza ETW)' 'Iniciá la captura, jugá o reproducí el problema y detené. Se guarda un .etl para abrir con Windows Performance Analyzer (DPC/ISR por driver).' $bp
Add-Action $bS $dEtw.Out { wpr.exe -start GeneralProfile -filemode 2>&1 | Out-String; 'Captura iniciada. Reproducí el problema y presioná "Detener y guardar".' } ''
Add-Action $bE $dEtw.Out { $f = "$script:Dir\porte-traza.etl"; wpr.exe -stop $f 2>&1 | Out-String; "Traza guardada en $f. Abrila con Windows Performance Analyzer y revisá DPC/ISR por driver (ndis.sys, dxgkrnl.sys, nvlddmkm.sys, amdkmdag, storport.sys, USB, audio, Bluetooth)." } ''
$script:Pages['lat'].Panel.Children.Add($dEtw.Card) | Out-Null
$bLm = Pill 'Abrir LatencyMon' 'Ghost'; $bLm.Add_Click({ Start-Process 'https://www.resplendence.com/latencymon' })
$script:Pages['lat'].Panel.Children.Add((New-Card 'LatencyMon' 'Herramienta gratuita que muestra qué driver genera DPC/ISR altos. Es la forma más simple de identificar al responsable antes de corregir.' $bLm)) | Out-Null

# =====================================================================
#   RED
# =====================================================================
Add-DiagCard 'net' 'Diagnóstico del adaptador' 'Driver, RSS, energía, interrupt moderation, offloads y TCP.' 'Analizar' { Get-NetDiag }
Add-DiagCard 'net' 'Prueba de red' 'Mide ping, jitter y pérdida contra tu router y contra internet por separado (unos 20 segundos).' 'Probar' {
    $gw = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1).NextHop
    $o = @('LATENCIA LOCAL (tu router)')
    if ($gw) { $o += Test-Ping $gw 30 } else { $o += 'No se encontró puerta de enlace.' }
    $o += 'INTERNET'; $o += Test-Ping '1.1.1.1' 30; $o += Test-Ping '8.8.8.8' 30
    $o += 'Lectura: pérdida o jitter altos ya contra el router apuntan a Wi-Fi, cable o placa local. Si el router va bien e internet no, es el proveedor o la ruta. Ningún tweak de TCP baja el ping físico al servidor.'
    $o
}

# =====================================================================
#   GPU Y PANTALLA
# =====================================================================
function Get-GpuAdvice {
    $lat = [bool]$script:wzLat.IsChecked; $gpuB = [bool]$script:wzGpu.IsChecked; $vrr = [bool]$script:wzVrr.IsChecked
    $l = @()
    if ($vrr) { $l += 'PANTALLA: activá G-SYNC/FreeSync en el driver, V-Sync ON en el panel del driver y OFF dentro del juego, y limitá los FPS unos 3 por debajo del refresco (ej.: 141 en 144 Hz). Es la combinación habitual para evitar tearing sin el retraso de un V-Sync completo.' }
    else { $l += 'PANTALLA: sin VRR, V-Sync OFF con un límite de FPS reduce latencia a costa de tearing. V-Sync ON agrega latencia.' }
    $l += 'NVIDIA: usá Reflex (On u On + Boost) dentro del juego si existe; con Reflex no hace falta el Low Latency Mode del panel. AMD: Anti-Lag 2 si el juego lo integra. Evitá Anti-Lag+ en juegos con anti-cheat: en 2023 causó bloqueos de VAC en Counter-Strike 2.'
    if ($gpuB) { $l += 'LIMITANTE GPU: Reflex y Low Latency ayudan más porque evitan que se acumule cola de render. Poné un límite de FPS un poco por debajo de lo que la GPU sostiene para no llegar al 100%.' }
    else { $l += 'LIMITANTE CPU: Low Latency y Reflex aportan menos. Atacá la contención de CPU (debloat, DPC, prioridades) y revisá el reloj sostenido.' }
    if ($lat) { $l += 'LATENCIA MÍNIMA: FPS altos y estables por encima del refresco, Reflex activo, sin V-Sync, y borderless solo si PresentMon confirma Independent Flip.' }
    $l += 'ENERGÍA: "Preferir máximo rendimiento" mantiene relojes altos (NVIDIA lo documenta) con más consumo; usalo por juego, no global.'
    $l += 'SHADER CACHE: dejalo habilitado. Texture filtering y threaded optimization: valores por defecto salvo que midas una mejora.'
    $l
}
Add-DiagCard 'gpu' 'Estado de la GPU' 'Driver, resolución, clocks, potencia y limitaciones activas (NVIDIA vía nvidia-smi).' 'Analizar' {
    $l = @(); foreach ($g in @(Get-CimInstance Win32_VideoController)) { $l += "$($g.Name) | driver $($g.DriverVersion) ($(Fmt-Date $g.DriverDate)) | $($g.CurrentHorizontalResolution)x$($g.CurrentVerticalResolution) @ $($g.CurrentRefreshRate) Hz" }
    $live = Get-GpuLive
    if ($live) { $l += $live; $l += 'Limitaciones activas:'; $l += (Get-GpuThrottle) } else { $l += 'nvidia-smi no está disponible: en AMD o Intel usá HWiNFO o GPU-Z para clocks, potencia y temperatura.' }
    $l += 'Modo de presentación real del juego: importá un CSV de PresentMon en Benchmark (Independent Flip, DirectFlip, Composed...).'
    $l
}
$script:wzLat = New-Object Windows.Controls.CheckBox; $script:wzLat.Style = $w.FindResource('Switch')
$script:wzGpu = New-Object Windows.Controls.CheckBox; $script:wzGpu.Style = $w.FindResource('Switch')
$script:wzVrr = New-Object Windows.Controls.CheckBox; $script:wzVrr.Style = $w.FindResource('Switch')
$script:Pages['gpu'].Panel.Children.Add((New-Card 'Asistente: priorizo latencia mínima' 'Para juegos competitivos: respuesta por encima de la calidad visual.' $script:wzLat)) | Out-Null
$script:Pages['gpu'].Panel.Children.Add((New-Card 'Asistente: mi limitante es la GPU' 'La GPU llega al 95-100% de uso mientras jugás.' $script:wzGpu)) | Out-Null
$script:Pages['gpu'].Panel.Children.Add((New-Card 'Asistente: mi monitor tiene G-SYNC o FreeSync' 'Frecuencia variable (VRR) activa en el monitor.' $script:wzVrr)) | Out-Null
Add-DiagCard 'gpu' 'Asistente: ver recomendación' 'Según los tres interruptores de arriba.' 'Ver recomendación' { Get-GpuAdvice }
$bDdu = Pill 'Abrir sitio de DDU' 'Ghost'; $bDdu.Add_Click({ Start-Process 'https://www.wagnardsoft.com' })
$script:Pages['gpu'].Panel.Children.Add((New-Card 'Instalación limpia del driver' '1) Bajá el driver oficial. 2) Arrancá en Modo Seguro. 3) Limpiá con DDU. 4) Instalá el driver. 5) Configurá y volvé a medir.' $bDdu)) | Out-Null

# =====================================================================
#   ALMACENAMIENTO
# =====================================================================
Add-DiagCard 'sto' 'Diagnóstico de almacenamiento' 'Salud, temperatura, desgaste, espacio libre, TRIM, indexado y driver NVMe.' 'Analizar' { Get-StoDiag }
$cleanDefs = @(
    @('Archivos temporales', 'Borra el contenido de las carpetas TEMP.', { Get-ChildItem $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue; if ($isAdmin) { Get-ChildItem "$env:windir\Temp" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }; 'Temporales borrados.' }),
    @('Vaciar papelera', 'Elimina definitivamente lo que hay en la papelera.', { Clear-RecycleBin -Force -ErrorAction SilentlyContinue; 'Papelera vaciada.' }),
    @('Caché DNS', 'Limpia la caché de resolución de nombres.', { ipconfig /flushdns | Out-Null; 'Caché DNS limpiada.' }),
    @('Caché de miniaturas', 'Borra las miniaturas guardadas del Explorador.', { Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue; 'Miniaturas borradas.' })
)
foreach ($cd in $cleanDefs) { $b = Pill 'Ejecutar' 'Ghost'; $d = New-Diag $cd[0] $cd[1] $b; Add-Action $b $d.Out $cd[2] $cd[0]; $script:Pages['sto'].Grid.Children.Add($d.Card) | Out-Null }

# =====================================================================
#   SEGURIDAD
# =====================================================================
Add-DiagCard 'sec' 'Estado actual' 'VBS, integridad de memoria (HVCI), Hyper-V, plataforma de máquina virtual y Defender.' 'Analizar' { Get-SecDiag }
Add-Info 'sec' 'Seguridad perdida contra ganancia real' "HVCI: entre 3% y 6% de FPS promedio en pruebas publicadas. Perdés protección de integridad de código en el kernel; algunos anti-cheats la exigen.`nVBS completo: alrededor de 3 a 7% según CPU y juego. Perdés VBS, HVCI y Credential Guard.`nHypervisor: ganancia pequeña. Perdés WSL2, Hyper-V, Sandbox y Docker.`nDefender: no se desactiva.`nRegla: medí antes y después. Si la ganancia no es claramente mayor que la variación entre corridas, no vale el riesgo."

# =====================================================================
#   TEMPERATURAS
# =====================================================================
function Format-Stress($d) {
    $f = @($d.f); $l = @()
    if ($f.Count -ge 10) {
        $a = ($f | Select-Object -First 5 | Measure-Object -Average).Average; $b = ($f | Select-Object -Last 5 | Measure-Object -Average).Average
        $drop = [math]::Round(100 * ($a - $b) / $a, 1)
        $l += "Reloj al inicio: $([int]$a) MHz | al final: $([int]$b) MHz | caída: $drop%"
        $l += "Reloj mínimo: $([int](($f | Measure-Object -Minimum).Minimum)) MHz"
        if (@($d.t).Count) { $l += "Temperatura máxima (ACPI): $(($d.t | Measure-Object -Maximum).Maximum) °C" }
        if ($drop -gt 10) { $l += 'Veredicto: el reloj cae más del 10% bajo carga sostenida. Posible thermal throttling o límite de potencia. Resolvelo (pasta, disipador, flujo de aire, límites de potencia) antes de tocar Windows.' }
        else { $l += 'Veredicto: sin señales claras de throttling en esta prueba sintética de CPU. No reemplaza medir en un juego real.' }
    } else { $l += 'No se pudo leer la frecuencia del CPU durante la prueba.' }
    $l -join "`n"
}
Add-DiagCard 'tmp' 'Instantánea térmica' 'Temperaturas, relojes y limitaciones activas ahora mismo.' 'Medir' {
    $l = @(); $ct = Get-CpuTemp
    $l += 'CPU (ACPI): ' + $(if ($ct) { "$ct °C" } else { 's/d - usá HWiNFO' })
    $g = Get-GpuLive; $l += 'GPU: ' + $(if ($g) { $g } else { 'sin nvidia-smi (usá GPU-Z o HWiNFO)' })
    if ($g) { $l += 'GPU limitaciones activas:'; $l += (Get-GpuThrottle) }
    $pf = Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq '_Total' } | Select-Object -First 1
    if ($pf) { $l += "CPU: $($pf.ProcessorFrequency) MHz ($($pf.PercentProcessorPerformance)% del rendimiento base)" }
    foreach ($d in @(Get-PhysicalDisk -ErrorAction SilentlyContinue)) { $r = $d | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue; if ($r -and $r.Temperature) { $l += "SSD $($d.FriendlyName): $($r.Temperature) °C" } }
    $l
}
$bStress = Pill 'Iniciar prueba (45 s)'
$dStress = New-Diag 'Prueba de estrés del CPU' 'Carga todos los núcleos 45 segundos y compara el reloj al inicio y al final. No uses la PC mientras corre.' $bStress
$script:StressOut = $dStress.Out
$script:StressTimer = New-Object Windows.Threading.DispatcherTimer; $script:StressTimer.Interval = [TimeSpan]::FromSeconds(1); $script:StressData = $null
$script:StressTimer.Add_Tick({
    $d = $script:StressData; if (-not $d) { return }
    $d.n++
    $p = Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq '_Total' } | Select-Object -First 1
    if ($p) { $d.f += [double]$p.ProcessorFrequency }
    $tc = Get-CpuTemp; if ($tc) { $d.t += [double]$tc }
    Say "Prueba de estrés: $($d.n)/45 s"
    if ($d.n -ge 45) { $script:StressTimer.Stop(); [Stress]::Stop(); $script:StressData = $null; Show-Out $script:StressOut (Format-Stress $d) }
})
Add-Action $bStress $script:StressOut {
    if ($script:StressData) { return 'Ya hay una prueba en curso.' }
    $script:StressData = @{ n = 0; f = @(); t = @() }
    [Stress]::Start([Environment]::ProcessorCount); $script:StressTimer.Start()
    'Corriendo 45 segundos. El resultado aparece acá.'
} ''
$script:Pages['tmp'].Panel.Children.Add($dStress.Card) | Out-Null

# =====================================================================
#   JUEGOS
# =====================================================================
$script:GameBox = New-Object Windows.Controls.TextBox
$script:GameBox.MinWidth = 520; $script:GameBox.Padding = [Windows.Thickness]::new(8,6,8,6); $script:GameBox.Margin = [Windows.Thickness]::new(0,10,0,0)
$script:GameBox.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, 'CardBrush'); $script:GameBox.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, 'TextBrush')
$script:GameBox.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, 'CardBorder'); $script:GameBox.SetResourceReference([Windows.Controls.Primitives.TextBoxBase]::CaretBrushProperty, 'TextBrush')
$bBrowse = Pill 'Buscar .exe' 'Ghost'
$gc = New-Card 'Juego (.exe)' 'Elegí el ejecutable del juego. Los ajustes de abajo se aplican solo a ese juego.' $bBrowse
$gc.Child.Children[1].Children.Add($script:GameBox) | Out-Null
$script:Pages['game'].Panel.Children.Add($gc) | Out-Null
$bBrowse.Add_Click({ $dlg = New-Object Microsoft.Win32.OpenFileDialog; $dlg.Filter = 'Ejecutables|*.exe'; if ($dlg.ShowDialog()) { $script:GameBox.Text = $dlg.FileName } })
function Get-GamePath { $p = $script:GameBox.Text.Trim('" '); if (-not $p -or -not (Test-Path $p)) { throw 'Elegí primero el .exe del juego.' }; $p }
$gameTw = @(
 @{Pg='game';Ph=2;N='Prioridad de CPU Alta (solo este juego)';Ev='Depende: medir';Rk='Bajo';Mod='HKLM\...\Image File Execution Options\<exe>\PerfOptions: CpuPriorityClass=3';Why='El juego arranca con prioridad Alta (nunca RealTime). Útil si hay contención de CPU con procesos en segundo plano.';Gn='Variable; mejor después del debloat';A={ $p = Get-GamePath; $exe = [IO.Path]::GetFileName($p); Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exe\PerfOptions" 'CpuPriorityClass' 3 }},
 @{Pg='game';Ph=1;N='GPU de alto rendimiento (solo este juego)';Ev='Probado';Rk='Bajo';Mod='HKCU\Software\Microsoft\DirectX\UserGpuPreferences: <ruta>=GpuPreference=2;';Why='En portátiles o equipos con dos GPU fuerza la GPU dedicada para este juego.';Hw='GPU integrada + dedicada';Gn='Alta si usaba la GPU equivocada';A={ $p = Get-GamePath; Set-Reg 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' $p 'GpuPreference=2;' 'String' }},
 @{Pg='game';Ph=2;N='Optimizaciones de pantalla completa OFF (solo este juego)';Ev='Depende: medir';Rk='Bajo';Mod='HKCU\...\AppCompatFlags\Layers: <ruta> = DISABLEDXMAXIMIZEDWINDOWEDMODE';Why='Algunos juegos funcionan mejor sin esa optimización. Verificá con PresentMon qué modo usa realmente antes y después.';Gn='Variable; a veces empeora';A={ $p = Get-GamePath; $k = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'; $old = [string](Get-Reg $k $p); $new = if ($old -match 'DISABLEDXMAXIMIZEDWINDOWEDMODE') { $old } elseif ($old) { "$old DISABLEDXMAXIMIZEDWINDOWEDMODE" } else { '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' }; Set-Reg $k $p $new 'String' }}
)
foreach ($t in $gameTw) { Add-TwCard $t }
$script:Cat += $gameTw

# =====================================================================
#   BENCHMARK
# =====================================================================
$bMeasure = Pill 'Medir ahora'; $bCsv = Pill 'Elegir CSV' 'Ghost'
$bSave = New-Object Windows.Controls.StackPanel; $bSave.Orientation = 'Horizontal'
$bA = Pill 'Guardar ANTES' 'Ghost'; $bA.Margin = [Windows.Thickness]::new(0,0,8,0)
$bD = Pill 'Guardar DESPUÉS' 'Ghost'; $bD.Margin = [Windows.Thickness]::new(0,0,8,0)
$bC = Pill 'Comparar'
$bSave.Children.Add($bA) | Out-Null; $bSave.Children.Add($bD) | Out-Null; $bSave.Children.Add($bC) | Out-Null
$bn = $script:Pages['bench'].Panel
$bn.Children.Add((New-Card 'Prueba rápida del sistema' 'Jitter del timer, puntaje relativo de CPU y DPC/interrupciones (unos 10 s). Medí con el juego cerrado y los mismos programas abiertos.' $bMeasure)) | Out-Null
$bn.Children.Add((New-Card 'Importar frametime' 'Elegí un CSV de PresentMon o CapFrameX: FPS promedio, 1% low, 0.1% low, stutters y el modo de presentación real (Independent Flip, DirectFlip...).' $bCsv)) | Out-Null
$bn.Children.Add((New-Card 'Antes y después' 'Guardá la medición actual y compará. Si empeoró, revertí.' $bSave)) | Out-Null
$dRes = New-Diag 'Resultados' 'Última medición.' (Nil ''); $script:BenchOut = $dRes.Out; $script:BenchOut.Text = 'Todavía no mediste nada.'; $script:BenchOut.Visibility = 'Visible'
$bn.Children.Add($dRes.Card) | Out-Null
$bMeasure.Add_Click({ Use-Busy 'Midiendo el sistema' {
    $script:BenchOut.Text = 'Midiendo...'; Say 'Midiendo timer...'
    $j = Measure-Jitter; $script:Cur.jitterAvg = $j.Avg; $script:Cur.jitterP99 = $j.P99
    Say 'Midiendo CPU...'; $script:Cur.cpu = Measure-Cpu
    Say 'Midiendo DPC e interrupciones...'; $d = Measure-Dpc
    if ($d) { $script:Cur.dpc = $d.Dpc; $script:Cur.intr = $d.Int }
    $script:BenchOut.Text = Format-Cur; Say 'Medición lista.'
} })
$bCsv.Add_Click({ Use-Busy 'Analizando frametime' {
    $dlg = New-Object Microsoft.Win32.OpenFileDialog; $dlg.Filter = 'CSV|*.csv'
    if (-not $dlg.ShowDialog()) { return }
    Say 'Leyendo CSV...'
    $rows = @(Import-Csv $dlg.FileName)
    $col = $rows[0].PSObject.Properties.Name | Where-Object { $_ -match '^(ms)?BetweenPresents$|^FrameTime$' } | Select-Object -First 1
    if (-not $col) { Say 'No encontré la columna MsBetweenPresents en ese CSV.'; return }
    $ft = @($rows | ForEach-Object { try { [double](([string]$_.$col).Replace(',', '.')) } catch { 0 } } | Where-Object { $_ -gt 0 })
    if ($ft.Count -lt 100) { Say 'El CSV tiene muy pocos frames.'; return }
    $s = $ft | Sort-Object -Descending; $n = $s.Count
    $k1 = [math]::Max(1, [int]($n * 0.01)); $k01 = [math]::Max(1, [int]($n * 0.001)); $med = $s[[int]($n / 2)]
    $script:Cur.fpsAvg = [math]::Round(1000 / ($ft | Measure-Object -Average).Average, 1)
    $script:Cur.low1 = [math]::Round(1000 / ($s[0..($k1 - 1)] | Measure-Object -Average).Average, 1)
    $script:Cur.low01 = [math]::Round(1000 / ($s[0..($k01 - 1)] | Measure-Object -Average).Average, 1)
    $script:Cur.stutters = @($ft | Where-Object { $_ -gt 2 * $med }).Count
    if ($rows[0].PSObject.Properties.Name -contains 'PresentMode') { $g = $rows | Group-Object PresentMode | Sort-Object Count -Descending | Select-Object -First 1; $script:Cur.mode = "$($g.Name) ($([math]::Round(100 * $g.Count / $rows.Count))% de los frames)" }
    $script:BenchOut.Text = Format-Cur; Say "Frametime importado ($n frames)."
} })
$bA.Add_Click({ Save-Bench 'antes' }); $bD.Add_Click({ Save-Bench 'despues' })
$bC.Add_Click({ $script:BenchOut.Text = Compare-Bench; $script:BenchOut.Visibility = 'Visible' })

# =====================================================================
#   PLAN POR FASES
# =====================================================================
function Build-PlanPhase([int]$ph) {
    $items = @($script:Cat | Where-Object { $_.Ph -eq $ph })
    if (-not $items.Count) { return 'Sin ajustes fijos en esta fase.' }
    ($items | ForEach-Object { $f = Get-TwFields $_
        "• $($_.N)  [$($_.Ev) · riesgo $($_.Rk)]`n    Modifica : $($_.Mod)`n    Por qué  : $($_.Why)`n    Hardware : $($f.Hw)`n    Ganancia : $($f.Gn)`n    Medir    : $($f.M)`n    Revertir : $($f.Rv)" }) -join "`n`n"
}
$script:PhaseNames = @{ 1 = 'FASE 1 - MUY SEGURO'; 2 = 'FASE 2 - ALTO IMPACTO'; 3 = 'FASE 3 - AVANZADO'; 4 = 'FASE 4 - EXPERIMENTAL'; 5 = 'FASE 5 - SOLO SI EL DIAGNÓSTICO LO JUSTIFICA' }
$phaseDesc = @{ 1 = 'Seguros y reversibles. Podés aplicarlos juntos.'; 2 = 'Mayor impacto probable. Uno por vez y medí.'; 3 = 'Requieren cuidado. Uno por vez.'; 4 = 'Pueden no aportar nada. Solo si el diagnóstico apunta ahí.'; 5 = 'Solo si el diagnóstico lo justifica y aceptás el riesgo.' }
foreach ($ph in 1..5) {
    $d = New-Diag $script:PhaseNames[$ph] $phaseDesc[$ph] (Nil ''); $d.Out.Text = Build-PlanPhase $ph; $d.Out.Visibility = 'Visible'
    $script:Pages['plan'].Panel.Children.Add($d.Card) | Out-Null
}
$nv = ($script:Cat | Where-Object { $_.Ev -like 'NO vale*' } | ForEach-Object { "• $($_.N): $($_.Why)" }) -join "`n"
$dNv = New-Diag 'NO VALE LA PENA' 'Mitos y ajustes que Porte no aplica.' (Nil ''); $dNv.Out.Text = $nv; $dNv.Out.Visibility = 'Visible'
$script:Pages['plan'].Panel.Children.Add($dNv.Card) | Out-Null
$mn = ($script:Cat | Where-Object { $_.Ev -eq 'Manual' } | ForEach-Object { "• $($_.N): $($_.Why)" }) -join "`n"
$dMn = New-Diag 'MANUAL (no se aplica desde Windows)' 'Quedan en tus manos, con la guía de qué hacer.' (Nil ''); $dMn.Out.Text = $mn; $dMn.Out.Visibility = 'Visible'
$script:Pages['plan'].Panel.Children.Add($dMn.Card) | Out-Null
Add-DiagCard 'plan' 'Exportar plan' 'Guarda el plan completo en tu Escritorio como Porte-Plan.md.' 'Exportar' {
    $o = @('# Porte Tweaking - Plan de optimización', '')
    foreach ($ph in 1..5) { $o += "## $($script:PhaseNames[$ph])"; $o += ''; $o += (Build-PlanPhase $ph); $o += '' }
    $o += '## NO VALE LA PENA'; $o += ''; foreach ($t in @($script:Cat | Where-Object { $_.Ev -like 'NO vale*' })) { $o += "- $($t.N): $($t.Why)" }
    $f = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Porte-Plan.md'
    ($o -join "`n") | Set-Content $f -Encoding UTF8
    "Plan guardado en $f"
}

# =====================================================================
#   MAX OPTIMIZER
# =====================================================================
$script:maxAdv = New-Object Windows.Controls.CheckBox; $script:maxAdv.Style = $w.FindResource('Switch')
function Get-MaxSet {
    if ($script:Lazy.ContainsKey('deb')) { $b = $script:Lazy['deb']; $script:Lazy.Remove('deb'); & $b }
    $adv = [bool]$script:maxAdv.IsChecked
    $maxPh = if ($adv) { 4 } else { 2 }
    $okRk = if ($adv) { @('Bajo', 'Medio') } else { @('Bajo') }
    @($script:checks | Where-Object {
        $t = $_.Tag
        (($t.Pg -in 'win', 'cpu', 'net', 'sto') -and ($t.Ph -ge 1) -and ($t.Ph -le $maxPh) -and ($okRk -contains $t.Rk)) -or
        (($t.Pg -eq 'deb') -and ($t.Tag -like 'VERDE*') -and (-not $t.Pkg))
    })
}
function Measure-Quick {
    $script:Cur = @{}
    $j = Measure-Jitter; $script:Cur.jitterAvg = $j.Avg; $script:Cur.jitterP99 = $j.P99
    $script:Cur.cpu = Measure-Cpu
    $d = Measure-Dpc; if ($d) { $script:Cur.dpc = $d.Dpc; $script:Cur.intr = $d.Int }
}
$bMax = Pill 'Max Optimizer'
$dMax = New-Diag 'Max Optimizer' 'Aplica de una vez los ajustes seguros de mayor impacto: punto de restauración, medición antes y después, y todo revertible con "Revertir todo".' $bMax
$script:MaxOut = $dMax.Out
$cAdv = New-Card 'Max Optimizer: incluir ajustes avanzados' 'Suma las fases 3 y 4 de riesgo medio (estado mínimo 100%, timers globales, interrupt moderation). Más calor y consumo; pueden no aportar nada.' $script:maxAdv
$hp = $script:Pages['home'].Panel
$hp.Children.Insert(1, $cAdv); $hp.Children.Insert(1, $dMax.Card)
Add-Action $bMax $script:MaxOut {
    if (-not $isAdmin) { return 'Necesitás ejecutar PowerShell como administrador.' }
    $sel = @(Get-MaxSet)
    if (-not $sel.Count) { return 'No hay ajustes para aplicar.' }
    $lista = ($sel | ForEach-Object { '- ' + $_.Tag.N }) -join "`n"
    $m = "Max Optimizer va a aplicar $($sel.Count) ajustes de una sola vez:`n`n$lista`n`nAntes crea un punto de restauración y mide el sistema; después vuelve a medir. Todo se revierte con 'Revertir todo'.`n`nNo incluye los de riesgo ALTO (HVCI, VBS, hypervisor): esos se aplican a mano en Seguridad.`n`n¿Continuar?"
    if ([Windows.MessageBox]::Show($m, 'Porte Tweaking', 'YesNo', 'Question', 'No') -ne 'Yes') { return 'Cancelado.' }
    Show-Busy 'Max Optimizer' 'Optimizando tu PC...'
    try {
        Say 'Midiendo ANTES (unos 10 s)...'; Measure-Quick; Save-Bench 'antes'
        $script:Undo = @(); $ok = 0; $fail = @()
        foreach ($c in $sel) {
            $t = $c.Tag; Say "Max Optimizer: $($t.N)..."
            try { & $t.A $t; Add-Content $script:JournalFile "$(Get-Date -Format s)  [MAX] $($t.N)"; $ok++ } catch { $fail += "$($t.N): $($_.Exception.Message)" }
        }
        Save-Undo
        Say 'Midiendo DESPUÉS (unos 10 s)...'; Measure-Quick; Save-Bench 'despues'
        $o = @("Aplicados: $ok de $($sel.Count)")
        if ($fail.Count) { $o += 'No se pudieron aplicar (el driver o el equipo no lo admite):'; $o += $fail }
        $o += ''; $o += (Compare-Bench); $o += ''
        $o += 'Varios cambios (HAGS, servicios, mouse) recién toman efecto al reiniciar. Reiniciá y volvé a medir con tu juego (CSV de PresentMon) para validar los 1% lows. Si algo empeoró: Revertir todo.'
    } finally { Hide-Busy }
    $o
} ''

# =====================================================================
#   FINAL: botones, ventana
# =====================================================================
foreach ($p in $script:Pages.Values) { $p.Panel.Children.Add($p.Grid) | Out-Null }
$BtnAll.Add_Click({
    $safe = @($script:checks | Where-Object { $_.Tag.Pg -eq $script:CurPage -and $_.Tag.Rk -ne 'Alto' })
    $on = [bool]($safe | Where-Object { -not $_.IsChecked })
    foreach ($c in $safe) { $c.IsChecked = $on }
})
$BtnApply.Add_Click({
    if (-not $isAdmin) { Say 'Necesitás ejecutar PowerShell como administrador.'; return }
    $sel = @($script:checks | Where-Object { $_.IsChecked -and $_.Tag.Pg -eq $script:CurPage })
    if (-not $sel.Count) { Say 'No seleccionaste ningún ajuste en esta pestaña.'; return }
    $adv = @($sel | Where-Object { $_.Tag.Ph -ge 2 })
    if ($adv.Count -gt 1) {
        $m = "Elegiste $($adv.Count) ajustes de fase 2 o superior.`n`nEl método es UN cambio por vez: si aplicás varios juntos no vas a saber cuál ayudó o empeoró.`n`n¿Aplicar todos igual?"
        if ([Windows.MessageBox]::Show($m, 'Porte Tweaking', 'YesNo', 'Question', 'No') -ne 'Yes') { Say 'Cancelado. Aplicá uno y medí.'; return }
    }
    $risky = @($sel | Where-Object { $_.Tag.Rk -eq 'Alto' })
    if ($risky.Count) {
        $m = "Ajustes de riesgo ALTO:`n`n" + (($risky | ForEach-Object { '- ' + $_.Tag.N + "`n  Se pierde: " + $_.Tag.Loss }) -join "`n") + "`n`nSe pueden revertir con 'Revertir todo'. ¿Continuar?"
        if ([Windows.MessageBox]::Show($m, 'Porte Tweaking', 'YesNo', 'Warning', 'No') -ne 'Yes') { Say 'Cancelado.'; return }
    }
    $script:Undo = @(); $ok = 0
    Show-Busy 'Aplicando ajustes' 'Un momento, no cierres la ventana'
    try {
        foreach ($c in $sel) {
            $t = $c.Tag; Say "Aplicando: $($t.N)..."
            try { & $t.A $t; Add-Content $script:JournalFile "$(Get-Date -Format s)  $($t.N)"; $ok++ } catch { Say "Error en $($t.N): $($_.Exception.Message)"; Wait-Ui 1500 }
        }
        Save-Undo
    } finally { Hide-Busy }
    Say "Listo: $ok ajustes aplicados. Reiniciá si el ajuste lo pide y medí en Benchmark."
})
$BtnRevert.Add_Click({ if (-not $isAdmin) { Say 'Necesitás ejecutar PowerShell como administrador.'; return }; Use-Busy 'Revirtiendo cambios' { Restore-All } })
$TitleBar.Add_MouseLeftButtonDown({ $w.DragMove() })
$BtnMin.Add_Click({ $w.WindowState = 'Minimized' }); $BtnClose.Add_Click({ $w.Close() })
$script:field.Targets.Add($Footer)
$script:Pages['home'].Nav.IsChecked = $true
$script:MsgIdx = 0
$script:Msgs = @(
    'Cualquier duda o consulta contactarse a mi discord: 7porte_',
    'Tip: medí antes y después de cada cambio (pestaña Benchmark).',
    'Tip: los ajustes de fase 2 o más conviene aplicarlos de a uno.',
    'Tip: si algo empeora, usá "Revertir todo".',
    'Cualquier duda o consulta contactarse a mi discord: 7porte_',
    'Tip: reiniciá después de aplicar HAGS, servicios o timers para que tomen efecto.',
    'Cualquier duda o consulta contactarse a mi discord: 7porte_',
    'Tip: el Plan por fases te explica qué hace cada ajuste y cómo revertirlo.',
    'Gracias por usar Porte Tweaking.'
)
function Show-Msg {
    $m = $script:Msgs[$script:MsgIdx % $script:Msgs.Count]; $script:MsgIdx++
    Write-Host ('[{0}] ' -f (Get-Date -Format 'HH:mm:ss')) -NoNewline -ForegroundColor DarkGray
    Write-Host $m -ForegroundColor $(if ($m -like '*discord*') { 'White' } else { 'Gray' })
}
Write-Host ''; Show-Msg
$script:MsgTimer = New-Object Windows.Threading.DispatcherTimer; $script:MsgTimer.Interval = [TimeSpan]::FromSeconds(10)
$script:MsgTimer.Add_Tick({ Show-Msg }); $script:MsgTimer.Start()
$w.ShowDialog() | Out-Null
$script:MsgTimer.Stop()
Write-Host ''; Write-Host 'Cualquier duda o consulta contactarse a mi discord: 7porte_' -ForegroundColor White
