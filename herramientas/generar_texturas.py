# Genera las texturas de assets/texturas/backrooms/ (papel tapiz, alfombra, placas de techo).
# Uso: python3 herramientas/generar_texturas.py assets/texturas/backrooms   (requiere numpy y Pillow)
import numpy as np, os, sys
from PIL import Image
out=sys.argv[1]; os.makedirs(out,exist_ok=True)
rng=np.random.default_rng(7)

def blur(a,sigma):
    # desenfoque periodico por FFT (tileable)
    h,w=a.shape[:2]
    fy=np.fft.fftfreq(h)[:,None]; fx=np.fft.fftfreq(w)[None,:]
    g=np.exp(-2*(np.pi**2)*(sigma**2)*(fx**2+fy**2))
    if a.ndim==2: return np.real(np.fft.ifft2(np.fft.fft2(a)*g))
    return np.stack([blur(a[...,i],sigma) for i in range(a.shape[2])],-1)
def ruido(n,sigma,seed=None):
    r=np.random.default_rng(seed) if seed is not None else rng
    a=blur(r.standard_normal((n,n)),sigma); a-=a.mean(); a/=a.std()+1e-9; return a
def norm01(a): a=a-a.min(); return a/(a.max()+1e-9)
def normal_map(h,fuerza):
    dx=(np.roll(h,-1,1)-np.roll(h,1,1))*0.5
    dy=(np.roll(h,1,0)-np.roll(h,-1,0))*0.5   # hacia arriba en la imagen
    n=np.stack([-dx*fuerza,-dy*fuerza,np.ones_like(h)],-1)
    n/=np.linalg.norm(n,axis=-1,keepdims=True)
    return ((n*0.5+0.5)*255).astype(np.uint8)
def guardar(a,nombre,modo=None):
    if a.dtype!=np.uint8: a=(np.clip(a,0,1)*255).astype(np.uint8)
    Image.fromarray(a).save(os.path.join(out,nombre))

# ---------------- papel tapiz amarillo (1024 px = 1 m) ----------------
N=1024; x=np.arange(N)[None,:].repeat(N,0); y=np.arange(N)[:,None].repeat(N,1)
per=128; u=(x%per)/per        # 8 franjas por metro
banda=np.where((u>0.10)&(u<0.90),1.0,0.0)
linea=np.exp(-((u-0.04)/0.012)**2)+np.exp(-((u-0.96)/0.012)**2)+0.7*np.exp(-((u-0.5)/0.35)**8)*0
# motivo de rombos suaves dentro de la banda ancha
v=(y%64)/64
rombo=np.clip(1-(np.abs(u-0.5)*2.2+np.abs(v-0.5)*1.1),0,1)
rombo=blur(rombo,1.2)
altura=0.35*banda+0.35*linea+0.22*rombo*banda
altura+=0.05*ruido(N,0.8)+0.03*ruido(N,4)
base=np.array([0.80,0.68,0.33])
tono=np.ones((N,N))*1.0
tono+= -0.17*linea + 0.07*rombo*banda - 0.075*(1-banda)
tono+= 0.035*ruido(N,0.6)+0.02*ruido(N,18,3)+0.015*ruido(N,60,4)
# manchas de humedad verticales (gotean desde arriba), periodicas
gotas=np.clip(ruido(N,40,5)*0.5+blur(rng.random((N,N))**6,3)*5,0,None)
tono-= 0.03*blur(gotas,2)
col=np.clip(base[None,None,:]*tono[...,None],0,1)
guardar(col,'papel_pared_color.jpg')
guardar(normal_map(altura,5.0),'papel_pared_normal.png')
rug=np.clip(0.78+0.1*ruido(N,1)-0.12*linea,0,1)
guardar(rug,'papel_pared_rugosidad.jpg')

# ---------------- alfombra humeda (1024 px = 1 m) ----------------
f=rng.standard_normal((N,N)); fibra=blur(f,0.7)+0.6*blur(f,1.6)
fibra=(fibra-fibra.mean())/fibra.std()
# hebras orientadas al azar por parches
parche=ruido(N,25,11)
ondas=np.sin((x*np.cos(parche*2)+y*np.sin(parche*2))*0.9)*0.5
alt=0.5*fibra+0.25*ondas+0.10*ruido(N,3,12)
mancha=ruido(N,30,13)*0.6+ruido(N,90,14)*0.8
base=np.array([0.58,0.47,0.24])
tono=1+0.11*fibra+0.06*ruido(N,2.5,15)+0.05*mancha
tono-=0.04*np.clip(ruido(N,45,16)-0.8,0,None)      # zonas humedas oscuras
col=np.clip(base[None,None,:]*tono[...,None]*np.array([1,1.0,0.97]),0,1)
guardar(col,'alfombra_color.jpg')
guardar(normal_map(alt,2.2),'alfombra_normal.png')
guardar(np.clip(0.92+0.05*ruido(N,1,17),0,1),'alfombra_rugosidad.jpg')

# ---------------- placa acustica de techo (2048 px = 1,5 m) ----------------
M=2048
def placa(variante,seed):
    r=np.random.default_rng(seed)
    yy,xx=np.mgrid[0:M,0:M]
    h=np.zeros((M,M)); tono=np.ones((M,M))
    # fisuras: trazos cortos de orientacion libre
    img=Image.new('L',(M,M),0)
    from PIL import ImageDraw
    d=ImageDraw.Draw(img)
    for _ in range(8000):
        cx,cy=r.integers(0,M,2); ang=r.uniform(0,np.pi); L=r.uniform(5,20)
        dx,dy=np.cos(ang)*L/2,np.sin(ang)*L/2
        d.line([cx-dx,cy-dy,cx+dx,cy+dy],fill=int(r.integers(60,160)),width=int(r.integers(1,3)))
    # perforaciones
    for _ in range(2600):
        cx,cy=r.integers(0,M,2); rad=r.uniform(1.6,3.4)
        d.ellipse([cx-rad,cy-rad,cx+rad,cy+rad],fill=255)
    fis=np.array(img).astype(float)/255
    fis=blur(fis,0.8)
    h-=0.55*fis
    tono-=0.20*fis
    # grano de la fibra
    g=blur(r.standard_normal((M,M)),1.0)
    h+=0.12*g; tono+=0.035*g
    # reveses perimetrales: borde rebajado + junta oscura
    bx=np.minimum(xx,M-1-xx); by=np.minimum(yy,M-1-yy); b=np.minimum(bx,by)
    chaf=np.clip(b/46,0,1)
    h+= (chaf-1)*0.9
    tono-= 0.16*(1-np.clip(b/10,0,1))
    tono-= 0.05*(1-chaf)
    # manchas
    def lowf(s,sg): 
        a=blur(r.standard_normal((M,M)),sg); a-=a.mean(); return a/a.std()
    tono+=0.02*lowf(1,140)
    if variante>=1:
        m=np.clip(lowf(2,120)-0.4,0,None)
        # humedad: concentrada hacia una esquina
        cx,cy=r.uniform(0.2,0.8)*M,r.uniform(0.2,0.8)*M
        rad=np.exp(-(((xx-cx)**2+(yy-cy)**2)/(2*(M*0.22)**2)))
        mancha=np.clip(rad*(0.75+0.25*lowf(3,80)),0,1)
        tono-=0.09*mancha*(0.5+0.5*variante)
        anillo=np.exp(-((np.sqrt((xx-cx)**2+(yy-cy)**2)-M*0.20)/9)**2)*(rad>0.2)
        tono-=0.04*anillo*variante
    base=np.array([0.86,0.845,0.78])
    col=np.clip(base[None,None,:]*tono[...,None],0,1)
    if variante>=1:
        col*= (1-0.22*mancha*(0.5+0.5*variante))[...,None]*np.array([1,0.95,0.80])[None,None,:]+ (0.22*mancha*(0.5+0.5*variante))[...,None]
    col=np.clip(col,0,1)
    return col,h
for i,(var,seed) in enumerate([(0,21),(1,22),(2,23)]):
    c,h=placa(var,seed)
    guardar(c,f'techo_placa_{i}_color.jpg')
    if i==0:
        guardar(normal_map(h,3.0),'techo_placa_normal.png')
        guardar(np.clip(0.88+0.06*blur(rng.standard_normal((M,M)),1.2),0,1),'techo_placa_rugosidad.jpg')
print('ok')
