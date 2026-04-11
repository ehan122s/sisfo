import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../authentication/data/auth_repository.dart';
import '../data/journal_repository.dart';

class DailyJournalScreen extends ConsumerStatefulWidget {
  const DailyJournalScreen({super.key});

  @override
  ConsumerState<DailyJournalScreen> createState() =>
      _DailyJournalScreenState();
}

class _DailyJournalScreenState
    extends ConsumerState<DailyJournalScreen> {

  List journals = [];

  bool loading = false;
  bool hasMore = true;

  int page = 0;
  int limit = 10;

  final scroll = ScrollController();

  @override
  void initState() {

    super.initState();

    scroll.addListener(() {

      if (scroll.position.pixels >
              scroll.position.maxScrollExtent - 200 &&
          !loading &&
          hasMore) {

        getData();

      }
    });

    getData();
  }

  Future getData() async {

    if (loading) return;

    setState(() => loading = true);

    final user =
        ref.read(authRepositoryProvider).currentUser;

    if (user == null) return;

    final data =
        await ref.read(journalRepositoryProvider)
            .getMyJournals(
      studentId: user.id,
      page: page,
      pageSize: limit,
    );

    setState(() {

      journals.addAll(data);

      page++;

      if (data.length < limit) {

        hasMore = false;

      }

      loading = false;

    });
  }

  Future refresh() async {

    journals.clear();

    page = 0;

    hasMore = true;

    await getData();
  }

  @override
  Widget build(BuildContext context) {

    int approved =
        journals.where((e) => e['is_approved'] == true).length;

    return Scaffold(

      backgroundColor: const Color(0xfff8fafc),

      body: RefreshIndicator(

        onRefresh: refresh,

        child: CustomScrollView(

          controller: scroll,

          slivers: [

            /// HEADER
            SliverAppBar(

              backgroundColor: Colors.white,

              elevation: 0,

              pinned: true,

              title: const Text(
                "Jurnal Harian",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0f172a),
                ),
              ),

              actions: [

                IconButton(

                  icon: const Icon(
                    LucideIcons.search,
                    color: Color(0xff64748b),
                  ),

                  onPressed: () {},
                )
              ],
            ),

            /// SUMMARY CARD
            SliverToBoxAdapter(

              child: Container(

                margin: const EdgeInsets.all(16),

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(

                  gradient: const LinearGradient(

                    colors: [
                      Color(0xff4f46e5),
                      Color(0xff6366f1),
                    ],
                  ),

                  borderRadius: BorderRadius.circular(26),

                  boxShadow: [

                    BoxShadow(

                      color: Colors.indigo.withOpacity(.25),

                      blurRadius: 18,

                      offset: const Offset(0, 6),

                    )
                  ],
                ),

                child: Row(

                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [

                    Column(

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const Text(
                          "Total Jurnal",
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          journals.length.toString(),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "$approved disetujui",
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),

                    Container(

                      padding:
                          const EdgeInsets.all(14),

                      decoration: BoxDecoration(

                        color: Colors.white
                            .withOpacity(.2),

                        borderRadius:
                            BorderRadius.circular(14),
                      ),

                      child: const Icon(
                        LucideIcons.book,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// LIST DATA
            SliverList(

              delegate:
                  SliverChildBuilderDelegate(

                (context, i) {

                  if (i == journals.length) {

                    return loading
                        ? const Padding(
                            padding:
                                EdgeInsets.all(20),
                            child: Center(
                              child:
                                  CircularProgressIndicator(),
                            ),
                          )
                        : const SizedBox();
                  }

                  final item = journals[i];

                  final status =
                      item['is_approved'] == true;

                  final date =
                      DateTime.parse(
                              item['created_at'])
                          .toLocal();

                  return Container(

                    margin:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),

                    decoration: BoxDecoration(

                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(24),

                      border: Border.all(
                        color:
                            const Color(0xfff1f5f9),
                      ),

                      boxShadow: [

                        BoxShadow(

                          blurRadius: 12,

                          color: Colors.black
                              .withOpacity(.04),

                        )
                      ],
                    ),

                    child: ListTile(

                      contentPadding:
                          const EdgeInsets.all(14),

                      leading:

                          /// FOTO
                          ClipRRect(

                        borderRadius:
                            BorderRadius.circular(14),

                        child: item['evidence_url'] != null
                            ? Image.network(
                                item['evidence_url'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: const Color(0xffeef2ff),
                                    child: const Icon(
                                      LucideIcons.image,
                                      color: Color(0xff6366f1),
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: const Color(0xffeef2ff),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(

                                    width: 60,
                                    height: 60,

                                    color: const Color(
                                        0xffeef2ff),

                                    child: const Icon(
                                      LucideIcons.image,
                                      color: Color(
                                          0xff6366f1),
                                    ),
                                  ),
                      ),

                      title: Text(
                        item['activity_title'] ??
                            "Tanpa judul",

                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          color:
                              Color(0xff0f172a),
                        ),
                      ),

                      subtitle: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          const SizedBox(height: 6),

                          Row(

                            children: [

                              const Icon(
                                LucideIcons.calendar,
                                size: 14,
                                color:
                                    Color(0xff94a3b8),
                              ),

                              const SizedBox(width: 6),

                              Text(

                                DateFormat(
                                  "d MMM yyyy",
                                  "id_ID",
                                ).format(date),

                                style:
                                    const TextStyle(
                                  fontSize: 12,
                                  color:
                                      Color(0xff64748b),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Container(

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),

                            decoration:
                                BoxDecoration(

                              color: status
                                  ? const Color(
                                          0xffdcfce7)
                                      .withOpacity(
                                          .8)
                                  : const Color(
                                          0xffffedd5)
                                      .withOpacity(
                                          .8),

                              borderRadius:
                                  BorderRadius
                                      .circular(20),
                            ),

                            child: Text(

                              status
                                  ? "Disetujui"
                                  : "Menunggu",

                              style: TextStyle(

                                fontSize: 11,

                                fontWeight:
                                    FontWeight.w600,

                                color: status
                                    ? const Color(
                                        0xff16a34a)
                                    : const Color(
                                        0xffea580c),
                              ),
                            ),
                          ),
                        ],
                      ),

                      trailing: const Icon(

                        LucideIcons.chevronRight,

                        color: Color(0xff94a3b8),

                      ),

                      onTap: () {

                        context.push(
                          "/journal/detail",
                          extra: item,
                        );

                      },
                    ),
                  );
                },

                childCount:
                    journals.length +
                        (hasMore ? 1 : 0),
              ),
            ),
          ],
        ),
      ),

      /// BUTTON TAMBAH
      floatingActionButton:

          FloatingActionButton.extended(

        onPressed: () async {

          final result =
              await context.push("/journal/create");

          if (result == true) {

            refresh();

          }
        },

        backgroundColor:
            const Color(0xff4f46e5),

        icon: const Icon(LucideIcons.plus),

        label: const Text("Tambah Jurnal"),
      ),
    );
  }
}