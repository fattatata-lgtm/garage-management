// Mengirim byte ESC/POS mentah (RAW) ke printer thermal dari server.
//  - NETWORK : socket TCP ke IP:9100 printer (printer LAN/WiFi, atau USB yang di-share lewat print server)
//  - SYSTEM  : printer yang sudah terpasang di OS server lewat spooler (Windows: winspool RAW, Linux/Mac: lp -o raw)
const net = require('net');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFile } = require('child_process');

const SEND_TIMEOUT_MS = 8000;

function sendNetwork(host, port, data) {
  return new Promise((resolve, reject) => {
    if (!host) return reject(new Error('Alamat IP printer belum diisi di Pengaturan.'));
    const socket = net.createConnection({ host, port: Number(port) || 9100 });
    let done = false;
    const finish = (err) => {
      if (done) return;
      done = true;
      socket.destroy();
      err ? reject(err) : resolve();
    };
    socket.setTimeout(SEND_TIMEOUT_MS, () => finish(new Error(`Printer ${host}:${port || 9100} tidak merespons (timeout).`)));
    socket.on('error', (e) => finish(new Error(`Tidak dapat terhubung ke printer ${host}:${port || 9100} (${e.code || e.message}).`)));
    socket.on('connect', () => {
      socket.end(data, () => setTimeout(() => finish(), 300)); // beri waktu buffer terkirim sebelum menutup
    });
  });
}

// Skrip PowerShell: tulis byte mentah ke antrean printer Windows (tanpa perlu printer di-share).
const PS_SCRIPT = `
param([Parameter(Mandatory=$true)][string]$PrinterName, [Parameter(Mandatory=$true)][string]$FilePath)
$src = @"
using System;
using System.Runtime.InteropServices;
public class RawPrinter {
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  public class DOCINFO {
    [MarshalAs(UnmanagedType.LPWStr)] public string pDocName;
    [MarshalAs(UnmanagedType.LPWStr)] public string pOutputFile;
    [MarshalAs(UnmanagedType.LPWStr)] public string pDataType;
  }
  [DllImport("winspool.drv", EntryPoint = "OpenPrinterW", SetLastError = true, CharSet = CharSet.Unicode)]
  static extern bool OpenPrinter(string name, out IntPtr h, IntPtr d);
  [DllImport("winspool.drv", SetLastError = true)] static extern bool ClosePrinter(IntPtr h);
  [DllImport("winspool.drv", EntryPoint = "StartDocPrinterW", SetLastError = true, CharSet = CharSet.Unicode)]
  static extern bool StartDocPrinter(IntPtr h, int level, [In] DOCINFO di);
  [DllImport("winspool.drv", SetLastError = true)] static extern bool EndDocPrinter(IntPtr h);
  [DllImport("winspool.drv", SetLastError = true)] static extern bool StartPagePrinter(IntPtr h);
  [DllImport("winspool.drv", SetLastError = true)] static extern bool EndPagePrinter(IntPtr h);
  [DllImport("winspool.drv", SetLastError = true)] static extern bool WritePrinter(IntPtr h, byte[] b, int count, out int written);
  public static void Send(string name, byte[] bytes) {
    IntPtr h;
    if (!OpenPrinter(name, out h, IntPtr.Zero)) throw new Exception("Printer '" + name + "' tidak ditemukan (kode " + Marshal.GetLastWin32Error() + ").");
    try {
      DOCINFO di = new DOCINFO(); di.pDocName = "Struk Bengkel"; di.pDataType = "RAW";
      if (!StartDocPrinter(h, 1, di)) throw new Exception("StartDocPrinter gagal (kode " + Marshal.GetLastWin32Error() + ").");
      try {
        StartPagePrinter(h);
        int w; if (!WritePrinter(h, bytes, bytes.Length, out w)) throw new Exception("WritePrinter gagal (kode " + Marshal.GetLastWin32Error() + ").");
        EndPagePrinter(h);
      } finally { EndDocPrinter(h); }
    } finally { ClosePrinter(h); }
  }
}
"@
Add-Type -TypeDefinition $src
[RawPrinter]::Send($PrinterName, [System.IO.File]::ReadAllBytes($FilePath))
`;

function run(cmd, args) {
  return new Promise((resolve, reject) => {
    execFile(cmd, args, { timeout: 15000, windowsHide: true }, (err, stdout, stderr) => {
      if (err) return reject(new Error((stderr || stdout || err.message).toString().trim().split('\n')[0] || err.message));
      resolve();
    });
  });
}

async function sendSystem(printerName, data) {
  if (!printerName) throw new Error('Nama printer belum diisi di Pengaturan.');
  const tmp = path.join(os.tmpdir(), `struk-${process.pid}-${Date.now()}`);
  const binFile = `${tmp}.bin`;
  await fs.promises.writeFile(binFile, data);
  const psFile = `${tmp}.ps1`;
  try {
    if (process.platform === 'win32') {
      await fs.promises.writeFile(psFile, PS_SCRIPT, 'utf8');
      await run('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', psFile, '-PrinterName', printerName, '-FilePath', binFile]);
    } else {
      await run('lp', ['-d', printerName, '-o', 'raw', binFile]);
    }
  } finally {
    fs.unlink(binFile, () => {});
    fs.unlink(psFile, () => {});
  }
}

module.exports = { sendNetwork, sendSystem };
