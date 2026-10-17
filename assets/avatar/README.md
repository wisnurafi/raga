# Raga Avatar - Asset Pack

Struktur:
- layers/  layer SVG 200x200 yang ditumpuk (urutan di avatar_manifest.json -> layerOrder)
- composites/  contoh avatar jadi (SVG + PNG 1024) untuk thumbnail / pratinjau
- mask/circle.svg  bentuk mask lingkaran
- avatar_manifest.json  daftar item, palet warna, default, dan syarat unlock

Cara menyusun (Flutter + flutter_svg):

    class AvatarView extends StatelessWidget {
      final String skin, hair, hairColor, shirt; final String? accessory, frame; final double size;
      const AvatarView({super.key, this.skin = 'skin-2', this.hair = 'short', this.hairColor = 'navy', this.shirt = 'lavender', this.accessory, this.frame, this.size = 160});
      Widget _l(String p) => SvgPicture.asset('assets/avatar/layers/$p', width: size, height: size);
      @override
      Widget build(BuildContext context) => SizedBox(width: size, height: size, child: Stack(children: [
        ClipOval(child: Stack(children: [
          _l('00_bg/bg.svg'),
          if (hair == 'wavy' || hair == 'bun') _l('01_back-hair/$hair-$hairColor.svg'),
          _l('02_shirt/$shirt.svg'), _l('03_neck/$skin.svg'), _l('04_head/$skin.svg'),
          _l('05_front-hair/$hair-$hairColor.svg'), _l('06_face/default.svg'),
          if (accessory != null) _l('07_accessory/$accessory.svg'),
        ])),
        if (frame != null) _l('08_frame/$frame.svg'),
      ]));
    }

Catatan:
- Bentuk badan avatar TIDAK berubah mengikuti berat badan. Progres avatar berasal dari kebiasaan (streak, jumlah catatan, level, target tercapai).
- Syarat unlock di manifest: streak_days, records_count, level, goal_reached.
- Layer berupa SVG, jadi tajam di semua ukuran. Untuk thumbnail kecil, pakai composites/*.png.
