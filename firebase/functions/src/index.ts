import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();

// Points awarded for different activities
const POINTS = {
  TASK_COMPLETED: 10,
  TRIP_COMPLETED: 25,
  STREAK_BONUS: 5,
  WEEKLY_BONUS: 50,
};

/**
 * Award points when a task is completed
 */
export const onTaskCompleted = functions.firestore
  .document('families/{familyId}/tasks/{taskId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Check if task was just completed
    if (before.status !== 'completed' && after.status === 'completed') {
      const familyId = context.params.familyId;
      const taskId = context.params.taskId;
      const userId = after.assignee;
      const points = after.points || POINTS.TASK_COMPLETED;
      
      // Update user points
      await updateUserPoints(familyId, userId, points);
      
      // Log activity
      await logActivity(familyId, {
        type: 'task_completed',
        refId: taskId,
        actorUid: userId,
        deltaPoints: points,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`Awarded ${points} points to ${userId} for completing task ${taskId}`);
    }
    
    return null;
  });

/**
 * Award points when a grocery trip is completed
 */
export const onTripCompleted = functions.firestore
  .document('families/{familyId}/groceryTrips/{tripId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Check if trip was just completed
    if (before.status !== 'completed' && after.status === 'completed') {
      const familyId = context.params.familyId;
      const tripId = context.params.tripId;
      const userId = after.assignee;
      const points = POINTS.TRIP_COMPLETED;
      
      // Update user points
      await updateUserPoints(familyId, userId, points);
      
      // Log activity
      await logActivity(familyId, {
        type: 'trip_completed',
        refId: tripId,
        actorUid: userId,
        deltaPoints: points,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`Awarded ${points} points to ${userId} for completing trip ${tripId}`);
    }
    
    return null;
  });

/**
 * Generate invite link when family is created
 */
export const onInviteCreated = functions.firestore
  .document('families/{familyId}')
  .onCreate(async (snapshot, context) => {
    const familyId = context.params.familyId;
    const familyData = snapshot.data();
    
    // Generate invite code
    const inviteCode = generateInviteCode();
    
    // Update family with invite code
    await snapshot.ref.update({
      inviteCode,
      inviteLink: `https://myfamily.app/join/${inviteCode}`,
    });
    
    console.log(`Generated invite code ${inviteCode} for family ${familyId}`);
    
    return null;
  });

/**
 * Anonymize user data when user is deleted
 */
export const onUserDelete = functions.auth
  .user()
  .onDelete(async (user) => {
    const uid = user.uid;
    
    // Anonymize user data in Firestore
    const batch = db.batch();
    
    // Update user document
    const userRef = db.collection('users').doc(uid);
    batch.update(userRef, {
      displayName: 'Deleted User',
      photoURL: null,
      email: null,
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // Update family member references
    const familiesQuery = await db.collection('families')
      .where('members', 'array-contains', uid)
      .get();
    
    familiesQuery.forEach((doc) => {
      const members = doc.data().members;
      const updatedMembers = members.filter((memberId: string) => memberId !== uid);
      
      batch.update(doc.ref, {
        members: updatedMembers,
      });
    });
    
    await batch.commit();
    
    console.log(`Anonymized data for deleted user ${uid}`);
    
    return null;
  });

/**
 * Update user points in family
 */
async function updateUserPoints(familyId: string, userId: string, points: number) {
  const memberRef = db.collection('families').doc(familyId).collection('members').doc(userId);
  
  await memberRef.update({
    points: admin.firestore.FieldValue.increment(points),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Log activity in family
 */
async function logActivity(familyId: string, activity: any) {
  await db.collection('families').doc(familyId).collection('activity').add(activity);
}

/**
 * Generate random invite code
 */
function generateInviteCode(): string {
  return Math.random().toString(36).substring(2, 8).toUpperCase();
}

/**
 * Weekly leaderboard calculation
 */
export const weeklyLeaderboard = functions.pubsub
  .schedule('0 0 * * 0') // Every Sunday at midnight
  .timeZone('America/New_York')
  .onRun(async (context) => {
    console.log('Running weekly leaderboard calculation');
    
    // Get all families
    const familiesSnapshot = await db.collection('families').get();
    
    for (const familyDoc of familiesSnapshot.docs) {
      const familyId = familyDoc.id;
      
      // Get all members with their points
      const membersSnapshot = await db.collection('families')
        .doc(familyId)
        .collection('members')
        .orderBy('points', 'desc')
        .get();
      
      // Award weekly bonus to top member
      if (!membersSnapshot.empty) {
        const topMember = membersSnapshot.docs[0];
        await updateUserPoints(familyId, topMember.id, POINTS.WEEKLY_BONUS);
        
        await logActivity(familyId, {
          type: 'weekly_leader',
          refId: topMember.id,
          actorUid: topMember.id,
          deltaPoints: POINTS.WEEKLY_BONUS,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        console.log(`Awarded weekly bonus to ${topMember.id} in family ${familyId}`);
      }
    }
    
    return null;
  });
