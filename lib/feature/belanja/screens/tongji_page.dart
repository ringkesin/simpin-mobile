import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kkba_mobile/core/utils/formatters.dart';
import 'package:kkba_mobile/core/widgets/kkba_loading_indicator.dart';
import 'package:kkba_mobile/theme.dart';

import '../models/tongji_model.dart';
import '../service/cart_api_service.dart';

class TongjiPage extends StatefulWidget {
  final CartApiService cartApiService;

  const TongjiPage({super.key, required this.cartApiService});

  @override
  State<TongjiPage> createState() => _TongjiPageState();
}

class _TongjiPageState extends State<TongjiPage> {
  TongjiBalanceModel? _balance;
  List<TongjiTransactionModel> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _lastPage = 1;

  bool get _hasMore => _currentPage < _lastPage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    widget.cartApiService.lastErrorMessage = null;
    final balance = await widget.cartApiService.getTongjiBalance();
    final balanceError = widget.cartApiService.lastErrorMessage;

    widget.cartApiService.lastErrorMessage = null;
    final transactionsPage =
        await widget.cartApiService.getTongjiTransactions();
    final transactionError = widget.cartApiService.lastErrorMessage;

    if (!mounted) return;

    setState(() {
      _balance = balance;
      _transactions = transactionsPage.items;
      _currentPage = transactionsPage.currentPage;
      _lastPage = transactionsPage.lastPage;
      _isLoading = false;
      _errorMessage =
          balance == null && transactionsPage.items.isEmpty
              ? (balanceError ?? transactionError)
              : null;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final nextPage = _currentPage + 1;
    widget.cartApiService.lastErrorMessage = null;
    final transactionsPage = await widget.cartApiService.getTongjiTransactions(
      page: nextPage,
    );
    final transactionError = widget.cartApiService.lastErrorMessage;

    if (!mounted) return;

    if (transactionError != null && transactionsPage.items.isEmpty) {
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(transactionError)));
      return;
    }

    setState(() {
      _transactions = [..._transactions, ...transactionsPage.items];
      _currentPage = transactionsPage.currentPage;
      _lastPage = transactionsPage.lastPage;
      _isLoadingMore = false;
    });
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    final formatter = DateFormat('dd/MM/yyyy', 'id_ID');
    final startText = start != null ? formatter.format(start) : '-';
    final endText = end != null ? formatter.format(end) : '-';
    return '$startText s.d. $endText';
  }

  String _formatTransactionDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(date.toLocal());
  }

  String _formatCurrencyWithSuffix(int value) {
    return '${formatRp(value)},-';
  }

  String _formatSignedAmount(TongjiTransactionModel transaction) {
    final baseAmount = formatRp(transaction.amount);
    return transaction.isDebit ? '-$baseAmount' : '+$baseAmount';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: KkbaLoadingIndicator());
    }

    if (_errorMessage != null && _balance == null && _transactions.isEmpty) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 14,
                    color: AppColors.secondaryTextLight,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInitialData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: true,
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primaryLight,
        onRefresh: _loadInitialData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
          children: [
            Text(
              'Saldo & Transaksi Tongji',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexendDeca(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryTextLight,
              ),
            ),
            const SizedBox(height: 20),
            _buildBalanceSection(),
            const SizedBox(height: 20),
            _buildTransactionSection(),
            if (_hasMore) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isLoadingMore ? null : _loadMore,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child:
                    _isLoadingMore
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          'Muat riwayat lainnya',
                          style: GoogleFonts.lexendDeca(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTextLight,
                          ),
                        ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSection() {
    final balance = _balance;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            balance?.periodeNama ?? '-',
            style: GoogleFonts.lexendDeca(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryTextLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDateRange(
              balance?.periodeStartDate,
              balance?.periodeEndDate,
            ),
            style: GoogleFonts.lexendDeca(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextLight,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Digunakan',
                  value: _formatCurrencyWithSuffix(balance?.usedAmount ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Sisa',
                  value: _formatCurrencyWithSuffix(
                    balance?.remainingAmount ?? 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6DEE8)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexendDeca(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexendDeca(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryTextLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaksi Tongji',
          style: GoogleFonts.lexendDeca(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryTextLight,
          ),
        ),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'Belum ada riwayat transaksi Tongji.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexendDeca(
                fontSize: 14,
                color: AppColors.secondaryTextLight,
              ),
            ),
          )
        else
          ..._transactions.map(_buildTransactionCard),
      ],
    );
  }

  Widget _buildTransactionCard(TongjiTransactionModel transaction) {
    final badgeColor =
        transaction.isDebit ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);
    final badgeTextColor =
        transaction.isDebit ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6DEE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  transaction.noTransaksiPenjualan?.isNotEmpty == true
                      ? transaction.noTransaksiPenjualan!
                      : transaction.id,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryTextLight,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  transaction.isDebit ? 'DEBIT' : 'KREDIT',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatTransactionDate(transaction.createdAt),
            style: GoogleFonts.lexendDeca(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextLight,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            transaction.description,
            style: GoogleFonts.lexendDeca(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextLight,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  transaction.periodeNama,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextLight,
                  ),
                ),
              ),
              Text(
                _formatSignedAmount(transaction),
                style: GoogleFonts.lexendDeca(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: badgeTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
