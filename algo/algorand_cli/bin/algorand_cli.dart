import 'dart:io';

import 'package:algorand_cli/algorand_cli.dart' as algorand_cli;
import 'package:algorand_cli/const.dart';
import 'package:algorand_dart/algorand_dart.dart';

void main(List<String> arguments) async {
  final algodClient = AlgodClient(
    apiUrl: PureStake.TESTNET_ALGOD_API_URL,
    apiKey: apiKey,
    tokenKey: PureStake.API_TOKEN_HEADER,
  );

  final indexerClient = IndexerClient(
    apiUrl: PureStake.TESTNET_INDEXER_API_URL,
    apiKey: apiKey,
    tokenKey: PureStake.API_TOKEN_HEADER,
  );

  final kmdClient = KmdClient(
    apiUrl: '127.0.0.1',
    apiKey: apiKey,
  );

  final algorand = Algorand(
    algodClient: algodClient,
    indexerClient: indexerClient,
    kmdClient: kmdClient,
  );

  final words1 =
      // ignore: lines_longer_than_80_chars
      'year crumble opinion local grid injury rug happy away castle minimum bitter upon romance federal entire rookie net fabric soft comic trouble business above talent';

  final words2 =
      // ignore: lines_longer_than_80_chars
      'beauty nurse season autumn curve slice cry strategy frozen spy panic hobby strong goose employ review love fee pride enlist friend enroll clip ability runway';

  final words3 =
      // ignore: lines_longer_than_80_chars
      'picnic bright know ticket purity pluck stumble destroy ugly tuna luggage quote frame loan wealth edge carpet drift cinnamon resemble shrimp grain dynamic absorb edge';

  final zenCoinManager = await Account.fromSeedPhrase(words1.split(' '));
  final user2 = await Account.fromSeedPhrase(words2.split(' '));
  final user3 = await Account.fromSeedPhrase(words3.split(' '));

  print('ZenCoinManager 1: ${zenCoinManager.publicAddress}');
  print('User 2: ${user2.publicAddress}');
  print('User 3: ${user3.publicAddress}');

  // Create a new asset
  // final assetId = await createAsset(
  //   algorand: algorand,
  //   sender: zenCoinManager,
  //   manager: zenCoinManager,
  // );

  // Update manager address
  // await changeManager(
  //   algorand: algorand,
  //   sender: account2,
  //   manager: account1,
  //   assetId: assetId,
  // );

  // Opt in the asset
  // account3, account2 opt-in asser (allow receive this asset)
  // await optIn(algorand: algorand, account: user3, assetId: assetId);
  // await optIn(algorand: algorand, account: user2, assetId: assetId);

  // Transfer the asset
  // await transfer(
  //   algorand: algorand,
  //   sender: zenCoinManager,
  //   receiver: user3,
  //   assetId: 107233672,
  // );

  // await transfer(
  //   algorand: algorand,
  //   sender: zenCoinManager,
  //   receiver: user2,
  //   assetId: 107233672,
  // );
  int balance1 = await algorand.getBalance(user2.publicAddress);
  int balance2 = await algorand.getBalance(user3.publicAddress);
  int balance3 = await algorand.getBalance(zenCoinManager.publicAddress);

  print('--- sender balance --- ${balance1}');
  print('--- recv balance --- ${balance2}');
  print('--- zenCoinManager balance --- ${balance3}');

  await atomicTransfer(
      algorand: algorand,
      sender: user2,
      receiver: user3,
      manager: zenCoinManager,
      assetId: 107233672);

  sleep(Duration(seconds: 5)); 

  balance1 = await algorand.getBalance(user2.publicAddress);
  balance2 = await algorand.getBalance(user3.publicAddress);
  balance3 = await algorand.getBalance(zenCoinManager.publicAddress);

  print('--- sender balance --- ${balance1}');
  print('--- recv balance --- ${balance2}');
  print('--- zenCoinManager balance --- ${balance3}');
}

Future<int> createAsset({
  required Algorand algorand,
  required Account sender,
  required Account manager,
}) async {
  print('--- Creating asset ---');

  // Get the suggested transaction params
  final params = await algorand.getSuggestedTransactionParams();

  // Create the asset
  final tx = await (AssetConfigTransactionBuilder()
        ..sender = sender.address
        ..totalAssetsToCreate = 10000
        ..decimals = 0
        ..unitName = 'aum'
        ..assetName = 'ZEN'
        ..url = 'http://zentech.io'
        ..metadataText = '16efaa3924a6fd9d3a4824799a4ac65d'
        ..defaultFrozen = false
        ..managerAddress = manager.address
        ..reserveAddress = manager.address
        ..freezeAddress = manager.address
        ..clawbackAddress = manager.address
        ..suggestedParams = params)
      .build();

  // Sign the transaction
  final signedTx = await tx.sign(sender);

  // Broadcast the transaction
  final txId = await algorand.sendTransaction(signedTx);
  final response = await algorand.waitForConfirmation(txId);
  final assetId = response.assetIndex ?? 0;

  // Print created asset
  printCreatedAsset(algorand: algorand, account: sender, assetId: assetId);

  // Print asset holding
  printAssetHolding(algorand: algorand, account: sender, assetId: assetId);

  return assetId;
}

void printCreatedAsset({
  required Algorand algorand,
  required Account account,
  required int? assetId,
}) async {
  final information = await algorand.getAccountByAddress(account.publicAddress);
  for (var asset in information.createdAssets) {
    if (asset.index == assetId) {
      print('Created asset: $asset');
      return;
    }
  }
}

void printAssetHolding({
  required Algorand algorand,
  required Account account,
  required int? assetId,
}) async {
  final information = await algorand.getAccountByAddress(account.publicAddress);
  for (var asset in information.assets) {
    if (asset.assetId == assetId) {
      print('Asset holding: $asset');
      return;
    }
  }
}

/// Opt in to receive an asset
Future optIn({
  required Algorand algorand,
  required Account account,
  required int assetId,
}) async {
  print('--- Opting in ---');
  // Get the suggested transaction params
  final params = await algorand.getSuggestedTransactionParams();

  // Opt in to the asset=
  final tx = await (AssetTransferTransactionBuilder()
        ..assetId = assetId
        ..receiver = account.address
        ..sender = account.address
        ..suggestedParams = params)
      .build();

  // Sign the transaction
  final signedTx = await tx.sign(account);

  // Broadcast the transaction
  final txId = await algorand.sendTransaction(signedTx);
  final response = await algorand.waitForConfirmation(txId);
  print(response);

  // Print created asset
  printAssetHolding(algorand: algorand, account: account, assetId: assetId);

  return Future.value();
}

Future changeManager({
  required Algorand algorand,
  required Account sender,
  required Account manager,
  required int assetId,
}) async {
  print('--- Changing manager address ---');

  // Get the suggested transaction params
  final params = await algorand.getSuggestedTransactionParams();

  // Create the asset
  final tx = await (AssetConfigTransactionBuilder()
        ..sender = sender.address
        ..assetId = assetId
        ..managerAddress = sender.address
        ..reserveAddress = manager.address
        ..freezeAddress = manager.address
        ..clawbackAddress = manager.address
        ..suggestedParams = params)
      .build();

  // Sign the transaction
  final signedTx = await tx.sign(sender);

  // Broadcast the transaction
  final txId = await algorand.sendTransaction(signedTx);
  final response = await algorand.waitForConfirmation(txId);
  print(response);

  // Print created asset
  printCreatedAsset(algorand: algorand, account: manager, assetId: assetId);

  return Future.value();
}

/// Transfer asset from creator to opted in account
Future<bool> transferWithManger({
  required Algorand algorand,
  required Account sender,
  required Account receiver,
  required Account manager,
  required int assetId,
}) async {
  print('--- Transfering asset ---');

  // Get the suggested transaction params
  final params = await algorand.getSuggestedTransactionParams();

  // Transfer the asset
  final tx = await (AssetTransferTransactionBuilder()
        ..assetId = assetId
        ..sender = sender.address
        ..receiver = receiver.address
        ..amount = 10
        ..suggestedParams = params)
      .build();

  // Sign the transaction
  final signedTx = await tx.sign(sender);

  // Broadcast the transaction
  final txId = await algorand.sendTransaction(signedTx);
  final response = await algorand.waitForConfirmation(txId);
  print(response);

  // Print created asset
  printAssetHolding(algorand: algorand, account: receiver, assetId: assetId);

  printAssetHolding(algorand: algorand, account: sender, assetId: assetId);

  return Future.value(true);
}

/// Transfer asset from creator to opted in account
Future<bool> transfer({
  required Algorand algorand,
  required Account sender,
  required Account receiver,
  required int assetId,
}) async {
  print('--- Transfering asset ---');

  // Get the suggested transaction params
  final params = await algorand.getSuggestedTransactionParams();

  // Transfer the asset
  final tx = await (AssetTransferTransactionBuilder()
        ..assetId = assetId
        ..sender = sender.address
        ..receiver = receiver.address
        ..amount = 10
        ..suggestedParams = params)
      .build();

  // Sign the transaction
  final signedTx = await tx.sign(sender);

  // Broadcast the transaction
  final txId = await algorand.sendTransaction(signedTx);
  final response = await algorand.waitForConfirmation(txId);
  print(response);

  // Print created asset
  printAssetHolding(algorand: algorand, account: receiver, assetId: assetId);

  printAssetHolding(algorand: algorand, account: sender, assetId: assetId);

  return Future.value(true);
}

/// Transfer asset from creator to opted in account
Future<bool> atomicTransfer({
  required Algorand algorand,
  required Account sender,
  required Account receiver,
  required Account manager,
  required int assetId,
}) async {
  print('--- atomicTransfer asset ---');

  // Get the suggested transaction params
  final params = await algorand.getSuggestedTransactionParams();

  TransactionParams customParams = TransactionParams(
    consensusVersion: params.consensusVersion,
    fee: 0,
    genesisId: params.genesisId,
    genesisHash: params.genesisHash,
    minFee: 0,
    lastRound: params.lastRound
  );


    final endRound = params.lastRound + 1000;


  // Create the first transaction
  final tx1 = await (AssetTransferTransactionBuilder()
        ..assetId = assetId
        ..sender = sender.address
        ..receiver = receiver.address
        ..amount = 1
        ..suggestedParams = params)
      .build();


    final params2 = await algorand.getSuggestedTransactionParams();
    
  final algoFee = Algo.fromMicroAlgos(tx1.fee ?? 0);
  print("tx1 fee: $algoFee AGLO");


  final tx2 = await (PaymentTransactionBuilder()
        ..sender = manager.address
        ..receiver = sender.address
        ..amount = Algo.toMicroAlgos(algoFee)
        ..suggestedParams = params2)
      .build();


  // Group the transaction
  AtomicTransfer.group([tx1, tx2]);

  // Sign the transaction
  final signedTx1 = await tx1.sign(sender);
  final signedTx2 = await tx2.sign(manager);

  final txId = await algorand.sendTransactions([signedTx1, signedTx2]);
  final response = await algorand.waitForConfirmation(txId);
  print(response);
  print(txId);

  return Future.value(true);
}

Future<bool> multisig({
  required Algorand algorand,
  required Account sender,
  required Account receiver,
  required Account manager,
  required int assetId,
}) async {
  final publicKeys = [sender.address, manager.address, receiver.address]
      .map((address) => Ed25519PublicKey(bytes: address.toBytes()))
      .toList();

  final msa = MultiSigAddress(
    version: 1,
    threshold: 2,
    publicKeys: publicKeys,
  );

  print('Multisignature address: ${msa.toString()}');

  // Fetch the suggested params
  final params = await algorand.getSuggestedTransactionParams();

  final tx = await (AssetTransferTransactionBuilder()
        ..sender = msa.toAddress()
        ..receiver = receiver.address
        ..assetId = assetId
        ..amount = 1
        ..suggestedParams = params)
      .build();

  // Sign the transaction for two accounts
  final signedTx = await msa.sign(account: manager, transaction: tx);
  final completeTx = await msa.append(account: sender, transaction: signedTx);

  try {
    final txId = await algorand.sendTransaction(completeTx);
    final response = await algorand.waitForConfirmation(txId);
    print(txId);
    print(response);
  } on AlgorandException catch (ex) {
    print(ex.message);
  }
  // Broadcast the transaction

  return Future.value(true);
}


// AK6Q33PDO4RJZQPHEMODC6PUE5AR2UD4FBU6TNEJOU4UR4KC6XL5PWW5K4 
// 77.721938 -> 77.700938

//7JXDK6Q7RAXLOLCT6CSZ36LELOHRUHQXJHZUMAKQKF6Z3IGNG65XK5AVSE
//325.309656

//IWR4CLLCN2TIVX2QPVVKVR5ER5OZGMWAV5QB2UIPYMPKBPLJZX4C37C4AA
//40.098935