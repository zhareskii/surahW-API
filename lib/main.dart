import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_audio/just_audio.dart'; //buat muter audio
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart'; // buat tampilan pas audionya diputar

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daftar Surah',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: SurahListPage(),
    );
  }
}

class SurahListPage extends StatefulWidget { //datar surah
  @override
  _SurahListPageState createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> { //pemutar audio
  List<Map<String, dynamic>> surahList = [];
  bool isLoading = true;
  final player = AudioPlayer();
  int? currentlyPlayingIndex;

  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    fetchSurah(); //tampilin nama surat

    player.positionStream.listen((position) {
      setState(() {
        currentPosition = position;
      });
    });

    player.durationStream.listen((duration) {
      setState(() {
        totalDuration = duration ?? Duration.zero;
      });
    });

    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) { //kalo di pause kembali di tampilan awal
        setState(() {
          currentlyPlayingIndex = null;
        });
      }
    });
  }

  Future<void> fetchSurah() async { //API services
    final response = await http.get(
      Uri.parse('https://quran-api.santrikoding.com/api/surah'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        surahList = data.map<Map<String, dynamic>>((item) {
          return {
            'nama_latin': item['nama_latin'],
            'deskripsi': item['deskripsi'],
            'audio': item['audio'],
          };
        }).toList();
        isLoading = false;
      });
    } else {
      throw Exception('Gagal mengambil data surah');
    }
  }

  Future<void> playOrPauseAudio(String url, int index) async { //buat pause/play audionya
    if (currentlyPlayingIndex == index && player.playing) {
      await player.pause();
    } else {
      await player.setUrl(url);
      await player.play();
      setState(() {
        currentlyPlayingIndex = index;
      });
    }
  }

  @override
  void dispose() { //bersihin resource biar memori ga penuh
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Surah Quran'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder( //bikin card yang bisa di scroll
              itemCount: surahList.length,
              itemBuilder: (context, index) {
                final surah = surahList[index];
                final isPlaying = currentlyPlayingIndex == index && player.playing;

                return Card( //isi item 
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surah['nama_latin'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          surah['deskripsi'],
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        SizedBox(height: 12),
                        if (isPlaying) ... [
                          ProgressBar(
                            progress: currentPosition,
                            total: totalDuration,
                            onSeek: (duration) {
                              player.seek(duration);
                            },
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.pause),
                                onPressed: () => playOrPauseAudio(surah['audio'], index),
                              ),
                              Text(
                                "${currentPosition.inMinutes.toString().padLeft(2, '0')}:${(currentPosition.inSeconds % 60).toString().padLeft(2, '0')} / ${totalDuration.inMinutes.toString().padLeft(2, '0')}:${(totalDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                              )
                            ],
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: () => playOrPauseAudio(surah['audio'], index),
                            icon: Icon(Icons.play_arrow),
                            label: Text('Putar Audio'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
